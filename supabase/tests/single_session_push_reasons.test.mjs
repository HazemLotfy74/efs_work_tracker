// Runs migrations/20261113090000_single_session_push_reasons.sql against an
// in-memory Postgres (PGlite) with a minimal copy of the live schema.
// Setup: npm install @electric-sql/pglite in <tmp>/efs-notification-verification
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {test} from 'node:test';

const require = createRequire(join(tmpdir(), 'efs-notification-verification', 'package.json'));
const {PGlite} = require('@electric-sql/pglite');

const employee = '11111111-1111-4111-8111-111111111111';
const admin = '22222222-2222-4222-8222-222222222222';
const other = '99999999-9999-4999-8999-999999999999';
const phoneA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const phoneB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const adminSession = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const otherSession = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const installA = 'a'.repeat(32);
const installB = 'b'.repeat(32);

async function database() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema private; create schema auth;
    create function auth.jwt() returns jsonb language sql stable as $$ select current_setting('request.jwt.claims',true)::jsonb $$;
    create function auth.uid() returns uuid language sql stable as $$ select (auth.jwt()->>'sub')::uuid $$;
    create table public.profiles(
      id uuid primary key, full_name text default 'Name', username text default 'user',
      employee_code text default 'E1', role text default 'employee',
      is_active bool default true, must_change_password bool default false,
      can_review_attendance_corrections bool default false,
      can_review_expense_advances bool default false, can_review_overtime bool default false);
    create table auth.sessions(id uuid primary key, user_id uuid, created_at timestamptz default clock_timestamp());
    create table public.notifications(id uuid primary key default gen_random_uuid(), recipient_id uuid not null,
      request_kind text default 'correction', event_type text default 'submitted', read_at timestamptz);
    create table public.attendance_correction_requests(
      id uuid primary key default gen_random_uuid(), status text not null default 'pending',
      review_note text check (length(review_note) <= 2000));
    create table private.scheduler_calls(at timestamptz default now());
    create function private.invoke_push_scheduler() returns bigint language sql as
      $$ insert into private.scheduler_calls default values; select 1::bigint $$;
    insert into public.profiles(id, role) values ('${employee}','employee'), ('${admin}','admin'), ('${other}','employee');
    insert into auth.sessions(id, user_id, created_at) values
      ('${phoneA}','${employee}', now() - interval '2 hours'),
      ('${adminSession}','${admin}', now() - interval '1 hour'),
      ('${otherSession}','${other}', now() - interval '1 hour');
    -- One decision made before the rule existed: it must survive the migration.
    insert into public.attendance_correction_requests(status) values ('rejected');
  `);
  await db.exec(await readFile(new URL('../ops/notification_push.sql', import.meta.url), 'utf8'));
  await db.exec(await readFile(
    new URL('../migrations/20261113090000_single_session_push_reasons.sql', import.meta.url), 'utf8'));
  return db;
}

const as = (db, user, session) =>
  db.exec(`set request.jwt.claims = '{"sub":"${user}","session_id":"${session}"}';`);
const one = async (db, sql, params = []) => Object.values((await db.query(sql, params)).rows[0])[0];
const login = (db, session, user, when = 'clock_timestamp()') =>
  db.exec(`insert into auth.sessions(id, user_id, created_at) values ('${session}','${user}', ${when});`);

test('a second sign-in takes the session away from the first phone', async () => {
  const db = await database();
  try {
    await as(db, employee, phoneA);
    assert.equal(await one(db, 'select private.is_active()'), true);
    assert.equal(await one(db, 'select private.require_actor()'), employee);
    assert.equal((await one(db, 'select public.get_account_status()')).session_state, 'current');
    await db.query('select public.register_push_device($1,$2)', [installA, 'token-a']);

    await login(db, phoneB, employee);

    // Phone A: refused everywhere, immediately, with no account data.
    await as(db, employee, phoneA);
    assert.equal(await one(db, 'select private.is_active()'), false);
    await assert.rejects(db.query('select private.require_actor()'), {code: '42501'});
    await assert.rejects(db.query('select public.register_push_device($1,$2)', [installA, 'token-a']), {code: '42501'});
    const lost = await one(db, 'select public.get_account_status()');
    assert.equal(lost.session_state, 'replaced');
    assert.equal(lost.full_name, undefined);
    assert.equal(lost.is_active, false);
    // ...and asking does not let it remove the new session.
    assert.equal(await one(db, 'select count(*)::int from auth.sessions where user_id = $1', [employee]), 2);

    // Phone B: active; its first account load ends phone A's session and push registration.
    await as(db, employee, phoneB);
    assert.equal(await one(db, 'select private.is_active()'), true);
    const status = await one(db, 'select public.get_account_status()');
    assert.equal(status.session_state, 'current');
    assert.equal(status.full_name, 'Name');
    assert.deepEqual((await db.query('select id from auth.sessions where user_id = $1', [employee])).rows, [{id: phoneB}]);
    assert.equal(await one(db, 'select count(*)::int from private.push_devices'), 0);

    // Phone A after that: still refused, and told why.
    await as(db, employee, phoneA);
    assert.equal(await one(db, 'select private.is_active()'), false);
    assert.equal((await one(db, 'select public.get_account_status()')).session_state, 'replaced');

    // Phone B signs out: phone A does not come back to life.
    await db.query('delete from auth.sessions where id = $1', [phoneB]);
    assert.equal(await one(db, 'select private.is_active()'), false);
    assert.equal((await one(db, 'select public.get_account_status()')).session_state, 'ended');

    // Other accounts were never affected.
    await as(db, other, otherSession);
    assert.equal(await one(db, 'select private.is_active()'), true);
    await as(db, admin, adminSession);
    assert.equal(await one(db, 'select private.is_admin()'), true);
    assert.equal(await one(db, 'select private.require_actor(true)'), admin);
  } finally { await db.close(); }
});

test('two sign-ins at the same instant leave exactly one active session', async () => {
  const db = await database();
  try {
    const instant = `'2026-11-13 10:00:00+00'`;
    await login(db, phoneB, employee, instant);
    await login(db, 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', employee, instant);
    let active = 0;
    for (const session of [phoneA, phoneB, 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee']) {
      await as(db, employee, session);
      if (await one(db, 'select private.is_active()')) active++;
    }
    assert.equal(active, 1);
  } finally { await db.close(); }
});

test('a forged or foreign session id is never active', async () => {
  const db = await database();
  try {
    await as(db, employee, otherSession); // another account's session id
    assert.equal(await one(db, 'select private.is_active()'), false);
    await as(db, employee, 'ffffffff-ffff-4fff-8fff-ffffffffffff'); // does not exist
    assert.equal(await one(db, 'select private.is_active()'), false);
    await db.exec(`set request.jwt.claims = '{"sub":"${employee}"}';`); // no session at all
    assert.equal(await one(db, 'select private.is_active()'), false);
    await assert.rejects(db.query('select private.require_actor()'), {code: '42501'});
  } finally { await db.close(); }
});

test('push goes only to the phone holding the active session, at once, with its subject', async () => {
  const db = await database();
  try {
    await as(db, employee, phoneA);
    await db.query('select public.register_push_device($1,$2)', [installA, 'token-a']);
    await db.query(`insert into public.notifications(recipient_id, request_kind, event_type) values ($1,'correction','approved')`, [employee]);
    assert.equal(await one(db, 'select count(*)::int from private.scheduler_calls'), 1, 'sender woken on insert');

    const claim = async () => (await db.query('select * from public.claim_push_deliveries()')).rows;
    const [job] = await claim();
    assert.equal(job.token, 'token-a');
    assert.equal(job.request_kind, 'correction');
    assert.equal(job.event_type, 'approved');
    await db.query('select public.finish_push_delivery($1,$2,$3,$4)', [job.id, job.lease, null, null]);

    // Signed in on phone B, which has not registered yet: phone A gets nothing more.
    await login(db, phoneB, employee);
    await db.query(`insert into public.notifications(recipient_id, request_kind, event_type) values ($1,'correction','rejected')`, [employee]);
    assert.deepEqual(await claim(), []);

    // Phone B registers: phone A's registration is replaced, B receives the pending one.
    await as(db, employee, phoneB);
    await db.query('select public.register_push_device($1,$2)', [installB, 'token-b']);
    assert.deepEqual((await db.query('select token from private.push_devices')).rows, [{token: 'token-b'}]);
    await db.query(`insert into public.notifications(recipient_id, request_kind, event_type) values ($1,'overtime','approved')`, [employee]);
    const again = await claim();
    assert.deepEqual(again.map((row) => row.token), ['token-b']);
    assert.deepEqual(await claim(), [], 'a claimed delivery is not handed out twice');

    // A notification for someone with no phone wakes nobody.
    const before = await one(db, 'select count(*)::int from private.scheduler_calls');
    await db.query('insert into public.notifications(recipient_id) values ($1)', [other]);
    assert.equal(await one(db, 'select count(*)::int from private.scheduler_calls'), before);

    await db.exec('set role authenticated');
    await assert.rejects(db.query('select * from public.claim_push_deliveries()'), {code: '42501'});
    await db.exec('reset role');
  } finally { await db.close(); }
});

test('a failing sender never blocks the business change', async () => {
  const db = await database();
  try {
    await as(db, employee, phoneA);
    await db.query('select public.register_push_device($1,$2)', [installA, 'token-a']);
    await db.exec(`create or replace function private.invoke_push_scheduler() returns bigint language plpgsql as
      $$ begin raise exception 'network down'; end $$;`);
    await db.query('insert into public.notifications(recipient_id) values ($1)', [employee]);
    assert.equal(await one(db, 'select count(*)::int from private.push_deliveries'), 1);
  } finally { await db.close(); }
});

test('a correction decision needs a written reason', async () => {
  const db = await database();
  try {
    const pending = async () => one(db, `insert into public.attendance_correction_requests default values returning id`);
    const set = (id, status, note) => db.query(
      `update public.attendance_correction_requests set status = $2, review_note = nullif(btrim($3::text), '') where id = $1`,
      [id, status, note]);

    for (const status of ['approved', 'rejected']) {
      for (const note of [null, '', '   ', '\n\t ']) {
        await assert.rejects(set(await pending(), status, note), {code: '22023'}, `${status} with ${JSON.stringify(note)}`);
      }
      await assert.rejects(set(await pending(), status, 'x'.repeat(2001)));
      const id = await pending();
      await set(id, status, '  Verified with the supervisor.  ');
      const row = (await db.query('select status, review_note from public.attendance_correction_requests where id = $1', [id])).rows[0];
      assert.deepEqual(row, {status, review_note: 'Verified with the supervisor.'});
    }
    // The table constraint alone also refuses it (e.g. if the trigger were dropped).
    await db.exec('alter table public.attendance_correction_requests disable trigger require_correction_decision_reason');
    await assert.rejects(set(await pending(), 'approved', null), {code: '23514'});
    await db.exec('alter table public.attendance_correction_requests enable trigger require_correction_decision_reason');

    // The decision made before the rule is still there, unchanged.
    assert.equal(await one(db, `select count(*)::int from public.attendance_correction_requests where status = 'rejected' and review_note is null`), 1);
    // A pending request can still be edited (e.g. assigned) without a reason.
    await set(await pending(), 'pending', null);
  } finally { await db.close(); }
});
