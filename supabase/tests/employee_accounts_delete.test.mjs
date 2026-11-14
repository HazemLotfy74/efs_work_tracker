// The "delete_employee" action of functions/employee-accounts, with the
// database and Supabase Auth replaced by recorders.
import assert from 'node:assert/strict';
import {test} from 'node:test';

globalThis.Deno = {
  env: {get: (key) => ({SUPABASE_URL: 'https://example.supabase.co', SUPABASE_ANON_KEY: 'anon', SUPABASE_SERVICE_ROLE_KEY: 'service'})[key]},
  serve: () => {},
};
const {createAccountHandler, supabaseTransport, AccountError} =
  await import('../functions/employee-accounts/index.ts');

const admin = '11111111-1111-4111-8111-111111111111';
const employee = '33333333-3333-4333-8333-333333333333';

function setup({mode = 'anonymized', dbError, authFails = false, authHasUser = true, actor = admin} = {}) {
  const calls = [];
  const handler = createAccountHandler({
    authenticate: async (token) => {
      calls.push(['authenticate', token]);
      return token === 'good' ? {id: actor} : null;
    },
    rpc: async (name, args) => {
      calls.push(['rpc', name, args]);
      if (dbError) throw Object.assign(new Error('db'), {code: dbError});
      return {mode};
    },
    deleteUser: async (id, soft) => {
      calls.push(['deleteUser', id, soft]);
      if (authFails) throw new AccountError(503, 'upstream_error', 'x');
      return authHasUser;
    },
  });
  const send = (body, token = 'good') => handler(new Request('https://f.test', {
    method: 'POST',
    headers: token ? {authorization: 'Bearer ' + token} : {},
    body: JSON.stringify(body),
  }));
  return {calls, send};
}
const deleteBody = {action: 'delete_employee', employee_id: employee};

test('no token, or a token Auth does not accept: nothing is touched', async () => {
  for (const token of [null, 'forged']) {
    const {calls, send} = setup();
    const response = await send(deleteBody, token);
    assert.equal(response.status, 401);
    assert.equal(calls.filter(([name]) => name !== 'authenticate').length, 0);
  }
});

test('the caller is taken from the verified token, never from the request', async () => {
  const {calls, send} = setup();
  const response = await send({...deleteBody, actor: 'someone-else', role: 'admin'});
  assert.equal(response.status, 400, 'extra fields are refused');
  assert.equal(calls.some(([name]) => name === 'rpc'), false);

  const ok = setup();
  await ok.send(deleteBody);
  assert.deepEqual(ok.calls.find(([name]) => name === 'rpc'),
    ['rpc', 'backend_delete_employee', {p_actor: admin, p_employee_id: employee}]);
});

test('the database refuses (not an admin, an admin target): 403 and Auth is not touched', async () => {
  const {calls, send} = setup({dbError: '42501'});
  const response = await send(deleteBody);
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error, 'forbidden');
  assert.equal(calls.some(([name]) => name === 'deleteUser'), false);
});

test('nobody deletes their own account here, admin or employee', async () => {
  for (const actor of [admin, employee]) {
    const {calls, send} = setup({actor});
    const response = await send({action: 'delete_employee', employee_id: actor.toUpperCase()});
    assert.equal(response.status, 403);
    assert.equal(calls.some(([name]) => name === 'rpc' || name === 'deleteUser'), false);
  }
});

test('invalid ids are refused before anything runs', async () => {
  for (const employee_id of [undefined, '', 'abc', "1'; drop table profiles;--", 42]) {
    const {calls, send} = setup();
    const response = await send({action: 'delete_employee', employee_id});
    assert.equal(response.status, 400);
    assert.equal(calls.some(([name]) => name === 'rpc'), false);
  }
});

test('history kept: the login is soft-deleted; nothing kept: it is removed', async () => {
  const kept = setup({mode: 'anonymized'});
  const first = await kept.send(deleteBody);
  assert.equal(first.status, 200);
  assert.deepEqual(await first.json(), {deleted: true, mode: 'anonymized'});
  assert.deepEqual(kept.calls.at(-1), ['deleteUser', employee, true]);
  // The database step always comes first.
  assert.deepEqual(kept.calls.map(([name]) => name), ['authenticate', 'rpc', 'deleteUser']);

  const gone = setup({mode: 'hard'});
  assert.deepEqual(await (await gone.send(deleteBody)).json(), {deleted: true, mode: 'hard'});
  assert.deepEqual(gone.calls.at(-1), ['deleteUser', employee, false]);
});

test('Auth fails after the database step: reported, and a retry finishes it', async () => {
  const failing = setup({authFails: true});
  const response = await failing.send(deleteBody);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error, 'auth_delete_pending');

  // The retry: the database says the record is already locked; Auth is asked again.
  const retry = setup({mode: 'anonymized'});
  assert.equal((await retry.send(deleteBody)).status, 200);
  assert.deepEqual(retry.calls.at(-1), ['deleteUser', employee, true]);

  // Hard delete whose answer was lost: the profile is gone, the Auth user may remain.
  const leftover = setup({mode: 'gone', authHasUser: true});
  assert.deepEqual(await (await leftover.send(deleteBody)).json(), {deleted: true, mode: 'hard'});
});

test('an id that was never an account is "not found", not a success', async () => {
  const {send} = setup({mode: 'gone', authHasUser: false});
  const response = await send(deleteBody);
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error, 'not_found');
});

test('no database detail or key ever reaches the caller', async () => {
  const {send} = setup({dbError: 'XX000'});
  const response = await send(deleteBody);
  const text = await response.text();
  assert.equal(response.status, 503);
  assert.doesNotMatch(text, /XX000|profiles|backend_|Bearer|service_role/);
});

test('the Auth call: admin endpoint, service key, soft flag; 404 means already gone', async () => {
  const requests = [];
  let status = 200;
  const transport = supabaseTransport({
    url: 'https://example.supabase.co', publicKey: 'anon', serviceKey: 'service',
    fetchImpl: async (url, options) => {
      requests.push({url, ...options});
      return status === 200
        ? Response.json({})
        : Response.json({code: 404, error_code: 'user_not_found'}, {status});
    },
  });
  assert.equal(await transport.deleteUser(employee, true), true);
  const [call] = requests;
  assert.equal(call.url, 'https://example.supabase.co/auth/v1/admin/users/' + employee);
  assert.equal(call.method, 'DELETE');
  assert.equal(call.headers.Authorization, 'Bearer service');
  assert.deepEqual(JSON.parse(call.body), {should_soft_delete: true});
  await transport.deleteUser(employee, false);
  assert.deepEqual(JSON.parse(requests[1].body), {should_soft_delete: false});

  status = 404;
  assert.equal(await transport.deleteUser(employee, true), false);
  status = 500;
  await assert.rejects(transport.deleteUser(employee, true));
});
