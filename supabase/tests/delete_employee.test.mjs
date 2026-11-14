// Runs migrations/20261113110000_delete_employee.sql against an in-memory
// Postgres (PGlite) with a minimal copy of the live schema: every foreign key to
// profiles is ON DELETE RESTRICT, as in production.
// Setup: npm install @electric-sql/pglite in <tmp>/efs-notification-verification
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {test} from 'node:test';

const require = createRequire(join(tmpdir(), 'efs-notification-verification', 'package.json'));
const {PGlite} = require('@electric-sql/pglite');

const admin = '11111111-1111-4111-8111-111111111111';
const admin2 = '22222222-2222-4222-8222-222222222222';
const worker = '33333333-3333-4333-8333-333333333333'; // has attendance history
const fresh = '44444444-4444-4444-8444-444444444444'; // never used the app
const other = '55555555-5555-4555-8555-555555555555';
const inactiveAdmin = '66666666-6666-4666-8666-666666666666';

async function database() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema private; create schema auth;
    create table public.profiles(
      id uuid primary key, full_name text not null, username text unique not null,
      employee_code text unique not null, role text not null default 'employee',
      is_active bool not null default true, must_change_password bool not null default false,
      phone text, can_review_expense_advances bool not null default false,
      can_review_attendance_corrections bool not null default false,
      can_review_overtime bool not null default false);
    create table auth.sessions(id uuid primary key default gen_random_uuid(), user_id uuid not null);
    create table private.push_devices(installation_id text primary key,
      user_id uuid not null references public.profiles(id) on delete cascade,
      session_id uuid not null references auth.sessions(id) on delete cascade, token text);
    create table private.employee_email_changes(
      employee_id uuid primary key references public.profiles(id) on delete restrict, new_email text);
    create table public.notifications(id uuid primary key default gen_random_uuid(),
      recipient_id uuid not null references public.profiles(id) on delete cascade);
    create table public.attendance_records(id uuid primary key default gen_random_uuid(),
      employee_id uuid not null references public.profiles(id) on delete restrict, work_date date);
    create function private.request_table(name text) returns void language plpgsql as $f$
    begin
      execute format($t$create table public.%I(
        id uuid primary key default gen_random_uuid(),
        employee_id uuid not null references public.profiles(id) on delete restrict,
        assigned_reviewer_id uuid references public.profiles(id) on delete restrict,
        status text not null default 'pending',
        reviewed_by uuid references public.profiles(id) on delete restrict,
        reviewed_at timestamptz, review_note text)$t$, name);
    end $f$;
    select private.request_table('expense_advance_requests');
    select private.request_table('overtime_requests');
    select private.request_table('attendance_correction_requests');
    -- A decision notifies the requester, as the live trigger does.
    create function private.notify() returns trigger language plpgsql as $f$
    begin
      if new.status <> old.status then
        insert into public.notifications(recipient_id) values (new.employee_id);
      end if;
      return new;
    end $f$;
    create trigger notify after update on public.expense_advance_requests
      for each row execute function private.notify();
    create function private.require_backend_admin(p_actor uuid) returns void language plpgsql as $f$
    begin
      if not exists (select 1 from public.profiles p where p.id = p_actor
          and p.role = 'admin' and p.is_active and not p.must_change_password) then
        raise exception 'Active admin required' using errcode = '42501';
      end if;
    end $f$;
    insert into public.profiles(id, full_name, username, employee_code, role, phone, can_review_expense_advances) values
      ('${admin}','Admin One','admin1','A1','admin',null,false),
      ('${admin2}','Admin Two','admin2','A2','admin',null,false),
      ('${worker}','Mona Ali','mona','E1','employee','+201000000001',true),
      ('${fresh}','New Hire','newhire','E2','employee','+201000000002',false),
      ('${other}','Omar Said','omar','E3','employee',null,false),
      ('${inactiveAdmin}','Old Admin','old','A3','admin',null,false);
    update public.profiles set is_active = false where id = '${inactiveAdmin}';
    insert into public.attendance_records(employee_id, work_date) values ('${worker}', '2026-11-01');
    insert into auth.sessions(user_id) values ('${worker}'), ('${worker}'), ('${fresh}'), ('${other}');
    insert into private.push_devices select 'dev-'||s.user_id, s.user_id, s.id, 't-'||s.id from auth.sessions s
      where s.id in (select min(id::text)::uuid from auth.sessions group by user_id);
    insert into private.employee_email_changes values ('${worker}', 'new@example.com');
    insert into public.notifications(recipient_id) values ('${worker}'), ('${worker}'), ('${other}');
    -- Mona: one decided and one pending request of her own; one of Omar's waits for her review.
    insert into public.expense_advance_requests(employee_id, status, reviewed_by, reviewed_at, review_note)
      values ('${worker}', 'approved', '${admin}', now(), 'ok');
    insert into public.expense_advance_requests(employee_id) values ('${worker}');
    insert into public.attendance_correction_requests(employee_id) values ('${worker}');
    insert into public.expense_advance_requests(employee_id, assigned_reviewer_id) values ('${other}', '${worker}');
  `);
  await db.exec(await readFile(
    new URL('../migrations/20261113110000_delete_employee.sql', import.meta.url), 'utf8'));
  return db;
}

const one = async (db, sql, params = []) => Object.values((await db.query(sql, params)).rows[0])[0];
const remove = (db, actor, target) =>
  one(db, 'select public.backend_delete_employee($1,$2)', [actor, target]);
const snapshot = async (db) => JSON.stringify({
  profiles: (await db.query('select * from public.profiles order by id')).rows,
  sessions: await one(db, 'select count(*)::int from auth.sessions'),
  requests: (await db.query('select employee_id, status, assigned_reviewer_id from public.expense_advance_requests order by id')).rows,
  notifications: await one(db, 'select count(*)::int from public.notifications'),
});

test('only an active admin can delete, and never themselves or another admin', async () => {
  const db = await database();
  try {
    const before = await snapshot(db);
    // A regular employee: another employee, and their own account.
    await assert.rejects(remove(db, other, worker), {code: '42501'});
    await assert.rejects(remove(db, worker, worker), {code: '42501'});
    // A deactivated admin, an unknown caller, no caller.
    await assert.rejects(remove(db, inactiveAdmin, worker), {code: '42501'});
    await assert.rejects(remove(db, '99999999-9999-4999-8999-999999999999', worker), {code: '42501'});
    await assert.rejects(remove(db, null, worker), {code: '42501'});
    // An admin: themselves, another admin (so the last admin can never go), nobody.
    await assert.rejects(remove(db, admin, admin), {code: '42501'});
    await assert.rejects(remove(db, admin, admin2), {code: '42501'});
    await assert.rejects(remove(db, admin, inactiveAdmin), {code: '42501'});
    await assert.rejects(remove(db, admin, null), {code: '22023'});
    assert.equal(await snapshot(db), before, 'a refused call changes nothing');
    assert.equal(await one(db, `select count(*)::int from public.profiles where role = 'admin' and is_active`), 2);
  } finally { await db.close(); }
});

test('the client roles cannot call it at all', async () => {
  const db = await database();
  try {
    for (const role of ['anon', 'authenticated']) {
      await db.exec(`set role ${role}`);
      await assert.rejects(remove(db, admin, worker), {code: '42501'});
      await db.exec('reset role');
    }
    await db.exec('set role service_role');
    assert.deepEqual(await remove(db, admin, fresh), {mode: 'hard'});
    await db.exec('reset role');
  } finally { await db.close(); }
});

test('an account nothing refers to is removed entirely', async () => {
  const db = await database();
  try {
    assert.deepEqual(await remove(db, admin, fresh), {mode: 'hard'});
    assert.equal(await one(db, 'select count(*)::int from public.profiles where id = $1', [fresh]), 0);
    assert.equal(await one(db, 'select count(*)::int from auth.sessions where user_id = $1', [fresh]), 0);
    assert.equal(await one(db, 'select count(*)::int from private.push_devices where user_id = $1', [fresh]), 0);
    // Repeating it (a retry after a lost answer) is harmless.
    assert.deepEqual(await remove(db, admin, fresh), {mode: 'gone'});
    // Nobody else was touched.
    assert.equal(await one(db, 'select count(*)::int from public.profiles'), 5);
    assert.equal(await one(db, 'select count(*)::int from auth.sessions where user_id = $1', [other]), 1);
  } finally { await db.close(); }
});

test('an account with history loses its access and personal data; the history stays', async () => {
  const db = await database();
  try {
    assert.deepEqual(await remove(db, admin, worker), {mode: 'anonymized'});

    const profile = (await db.query('select * from public.profiles where id = $1', [worker])).rows[0];
    assert.equal(profile.is_active, false);
    assert.equal(profile.phone, null);
    assert.equal(profile.can_review_expense_advances, false);
    assert.equal(profile.deleted_by, admin);
    assert.ok(profile.deleted_at);
    // Kept so the retained history still says whose it was.
    assert.equal(profile.full_name, 'Mona Ali');
    assert.equal(profile.employee_code, 'E1');

    // Access and personal records: gone.
    for (const [table, column] of [['auth.sessions', 'user_id'], ['private.push_devices', 'user_id'],
      ['private.employee_email_changes', 'employee_id'], ['public.notifications', 'recipient_id']]) {
      assert.equal(await one(db, `select count(*)::int from ${table} where ${column} = $1`, [worker]), 0, table);
    }
    // Business history: kept, consistent, nothing orphaned.
    assert.equal(await one(db, 'select count(*)::int from public.attendance_records where employee_id = $1', [worker]), 1);
    const own = (await db.query(
      'select status, reviewed_by, review_note from public.expense_advance_requests where employee_id = $1 order by reviewed_at', [worker])).rows;
    assert.deepEqual(own.map((r) => r.status).sort(), ['approved', 'rejected']);
    assert.ok(own.some((r) => r.review_note === 'ok'), 'an earlier decision is untouched');
    assert.ok(own.some((r) => r.review_note === 'Employee account deleted' && r.reviewed_by === admin));
    assert.equal(await one(db, `select status from public.attendance_correction_requests where employee_id = $1`, [worker]), 'rejected');
    // Omar's request that waited for Mona is back with the admins, still pending.
    const omar = (await db.query('select status, assigned_reviewer_id from public.expense_advance_requests where employee_id = $1', [other])).rows[0];
    assert.deepEqual(omar, {status: 'pending', assigned_reviewer_id: null});
    assert.equal(await one(db, 'select count(*)::int from public.notifications where recipient_id = $1', [other]), 1);

    // Repeating it changes nothing.
    const after = await snapshot(db);
    assert.deepEqual(await remove(db, admin2, worker), {mode: 'anonymized'});
    assert.equal(await snapshot(db), after);
  } finally { await db.close(); }
});

test('a deleted account can never be changed or brought back', async () => {
  const db = await database();
  try {
    await remove(db, admin, worker);
    await assert.rejects(db.query('update public.profiles set is_active = true where id = $1', [worker]), {code: '42501'});
    await assert.rejects(db.query('update public.profiles set can_review_overtime = true where id = $1', [worker]), {code: '42501'});
    await assert.rejects(db.query(`update public.profiles set role = 'admin' where id = $1`, [worker]), {code: '42501'});
    await assert.rejects(db.query('delete from public.profiles where id = $1', [worker]), (error) => ['23001', '23503'].includes(error.code));
    // Other accounts are edited as before.
    await db.query('update public.profiles set full_name = $2 where id = $1', [other, 'Omar S.']);
  } finally { await db.close(); }
});

test('a failure in the middle leaves everything as it was', async () => {
  const db = await database();
  try {
    const before = await snapshot(db);
    await db.exec(`create function private.boom() returns trigger language plpgsql as
      $f$ begin raise exception 'disk full'; end $f$;
      create trigger boom before delete on public.notifications for each row execute function private.boom();`);
    await assert.rejects(remove(db, admin, worker));
    assert.equal(await snapshot(db), before);
    assert.equal(await one(db, 'select deleted_at is null from public.profiles where id = $1', [worker]), true);
  } finally { await db.close(); }
});
