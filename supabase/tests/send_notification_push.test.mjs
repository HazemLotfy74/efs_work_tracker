import assert from 'node:assert/strict';

const pair = await crypto.subtle.generateKey(
  {name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: Uint8Array.of(1, 0, 1), hash: 'SHA-256'},
  true,
  ['sign', 'verify'],
);
const encodedKey = Buffer.from(await crypto.subtle.exportKey('pkcs8', pair.privateKey)).toString('base64');
const env = {
  PUSH_WORKER_SECRET: 'test-secret',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'test-role',
  FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({
    project_id: 'efs-work-tracker', client_email: 'example@example.com',
    private_key: '-----BEGIN PRIVATE KEY-----\n' + encodedKey + '\n-----END PRIVATE KEY-----',
  }),
};
let handler;
globalThis.Deno = {env: {get: key => env[key]}, serve: callback => {handler = callback;}};
const finished = [];
globalThis.fetch = async (url, options) => {
  if (url === 'https://oauth2.googleapis.com/token') {
    assert.ok(options.body.get('assertion').split('.').length === 3);
    return Response.json({access_token: 'test-access'});
  }
  if (url.endsWith('/claim_push_deliveries')) return Response.json(
    ['sent', 'throttle', 'invalid'].map(token => ({id: token, lease: 'test-lease', token, attempts: 1})),
  );
  if (url.endsWith('/finish_push_delivery')) {
    finished.push(JSON.parse(options.body));
    return new Response(null, {status: 204});
  }
  assert.match(url, /\/efs-work-tracker\/messages:send$/);
  const {message} = JSON.parse(options.body);
  assert.deepEqual(message.data, {route: 'alerts'});
  assert.equal(message.notification.body, 'You have a new notification.');
  assert.equal(message.android.notification.tag, message.token);
  if (message.token === 'throttle') return new Response(null, {status: 429, headers: {'Retry-After': '120'}});
  if (message.token === 'invalid') return Response.json(
    {error: {details: [{errorCode: 'UNREGISTERED'}]}}, {status: 404},
  );
  return Response.json({name: 'accepted'});
};
await import('../functions/send-notification-push/index.ts');
const request = headers => new Request('https://example.test', {method: 'POST', headers});
assert.equal((await handler(request({}))).status, 401);
const result = await handler(request({'X-Push-Worker-Secret': 'test-secret'}));
assert.equal(result.status, 200);
assert.deepEqual(await result.json(), {sent: 1, retry: 1, failed: 1, leasePending: 0});
assert.equal(finished.find(job => job.p_id === 'throttle').p_retry_seconds, 120);
assert.equal(finished.find(job => job.p_id === 'invalid').p_invalid_token, 'invalid');
assert.equal(finished.find(job => job.p_id === 'sent').p_retry_seconds, null);
console.log('Push sender passed: authentication, generic payload, retry delay, and invalid token handling.');

