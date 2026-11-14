type Delivery = {
  id: string; lease: string; token: string; attempts: number;
  // Present once claim_push_deliveries returns them (migration 20261113090000).
  request_kind?: string | null; event_type?: string | null;
};
type FirebaseAccount = { project_id: string; client_email: string; private_key: string };

const tokenEndpoint = 'https://oauth2.googleapis.com/token';
const requestTimeout = () => AbortSignal.timeout(10_000);
const bytes = (value: string) => new TextEncoder().encode(value);

function base64url(value: Uint8Array): string {
  return btoa(String.fromCharCode(...value)).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

async function googleAccessToken(account: FirebaseAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: tokenEndpoint,
    iat: now,
    exp: now + 3300,
  };
  const unsigned = [
    base64url(bytes(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))),
    base64url(bytes(JSON.stringify(claims))),
  ].join('.');
  const pem = account.private_key.replace(/-----[^-]+-----|\s/g, '');
  const key = await crypto.subtle.importKey(
    'pkcs8', Uint8Array.from(atob(pem), (character) => character.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, bytes(unsigned));
  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: unsigned + '.' + base64url(new Uint8Array(signature)),
    }),
    signal: requestTimeout(),
  });
  if (!response.ok) throw new Error('Google authentication failed');
  const result = await response.json();
  if (typeof result.access_token !== 'string') throw new Error('Missing Google access token');
  return result.access_token;
}

async function rpc(name: string, body: Record<string, unknown> = {}) {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) throw new Error('Missing Supabase server configuration');
  const response = await fetch(url + '/rest/v1/rpc/' + name, {
    method: 'POST',
    headers: { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    signal: requestTimeout(),
  });
  if (!response.ok) throw new Error('Database RPC failed');
  const result = await response.text();
  return result ? JSON.parse(result) : null;
}

// What the phone shows. It says what happened and nothing personal: no name,
// amount or reason is put on a lock screen. Arabic is the app's default language.
const subjects: Record<string, string> = {
  correction: 'طلب تصحيح حضور',
  expense_advance: 'طلب سلفة',
  overtime: 'طلب عمل إضافي',
};
const events: Record<string, string> = {
  submitted: 'طلب جديد بانتظار المراجعة.',
  assigned: 'تم إسناد طلب إليك للمراجعة.',
  approved: 'تمت الموافقة على طلبك.',
  rejected: 'تم رفض طلبك. افتح التطبيق لمعرفة السبب.',
};

export function notificationText(delivery: Pick<Delivery, 'request_kind' | 'event_type'>) {
  const title = subjects[delivery.request_kind ?? ''];
  const body = events[delivery.event_type ?? ''];
  return title && body
    ? { title, body }
    : { title: 'Efs WorkTrack', body: 'لديك إشعار جديد.' };
}

function retrySeconds(delivery: Delivery, retryAfter: string | null): number {
  const requested = retryAfter == null ? 0 : /^\d+$/.test(retryAfter)
    ? Number(retryAfter) : Math.ceil((Date.parse(retryAfter) - Date.now()) / 1000);
  return Math.max(60 * 2 ** (delivery.attempts - 1), Number.isFinite(requested) ? requested : 0);
}

async function send(delivery: Delivery, project: string, accessToken: string) {
  let retry: number | null = null;
  let invalid: string | null = null;
  let outcome: 'sent' | 'retry' | 'failed' = 'failed';
  try {
    const response = await fetch('https://fcm.googleapis.com/v1/projects/' + project + '/messages:send', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + accessToken, 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: {
        token: delivery.token,
        notification: notificationText(delivery),
        data: { route: 'alerts' },
        // HIGH + the app's "alerts" channel: shown at once, with sound, also
        // when the phone is idle. Kept for a day if the phone is offline.
        // The tag makes a retried send replace, not duplicate, the alert.
        android: {
          priority: 'HIGH',
          ttl: '86400s',
          notification: { tag: delivery.id, channel_id: 'alerts' },
        },
      } }),
      signal: requestTimeout(),
    });
    if (response.ok) {
      outcome = 'sent';
    } else {
      const error = await response.json().catch(() => null);
      const details = error?.error?.details;
      if (Array.isArray(details) && details.some((detail) => detail?.errorCode === 'UNREGISTERED')) {
        invalid = delivery.token;
      } else if (response.status !== 400) {
        retry = retrySeconds(delivery, response.headers.get('Retry-After'));
        outcome = 'retry';
      }
    }
  } catch (_) {
    retry = retrySeconds(delivery, null);
    outcome = 'retry';
  }
  await rpc('finish_push_delivery', {
    p_id: delivery.id, p_lease: delivery.lease, p_retry_seconds: retry, p_invalid_token: invalid,
  });
  return outcome;
}

async function authorized(request: Request): Promise<boolean> {
  const schedulerToken = request.headers.get('X-Push-Scheduler-Token');
  if (schedulerToken !== null) {
    if (!/^[a-f0-9]{64}$/.test(schedulerToken)) return false;
    try {
      return await rpc('verify_push_scheduler_token', { p_token: schedulerToken }) === true;
    } catch (_) {
      return false;
    }
  }
  const secret = Deno.env.get('PUSH_WORKER_SECRET');
  if (!secret) return false;
  const [expected, actual] = await Promise.all([
    crypto.subtle.digest('SHA-256', bytes(secret)),
    crypto.subtle.digest('SHA-256', bytes(request.headers.get('X-Push-Worker-Secret') ?? '')),
  ]);
  const received = new Uint8Array(actual);
  let diff = 0;
  new Uint8Array(expected).forEach((value, index) => { diff |= value ^ received[index]; });
  return diff === 0;
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response(null, { status: 405 });
  if (!await authorized(request)) return new Response(null, { status: 401 });
  try {
    const account: FirebaseAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '{}');
    if (!account.client_email || !account.private_key || !/^[a-z0-9-]+$/.test(account.project_id ?? '')) {
      return new Response('Firebase configuration missing', { status: 503 });
    }
    const accessToken = await googleAccessToken(account);
    const deliveries: Delivery[] = await rpc('claim_push_deliveries');
    const results = await Promise.allSettled(deliveries.map((delivery) => send(delivery, account.project_id, accessToken)));
    const counts = { sent: 0, retry: 0, failed: 0, leasePending: 0 };
    for (const result of results) {
      if (result.status === 'fulfilled') counts[result.value]++;
      else counts.leasePending++;
    }
    return Response.json(counts);
  } catch (_) {
    return new Response('Push worker unavailable', { status: 503 });
  }
});

