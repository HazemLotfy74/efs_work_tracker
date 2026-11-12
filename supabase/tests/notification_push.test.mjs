import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';

const require = createRequire(join(tmpdir(), 'efs-notification-verification', 'package.json'));
const {PGlite} = require('@electric-sql/pglite');
const db = new PGlite();
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
const session = '33333333-3333-4333-8333-333333333333';
const installation = '0'.repeat(32);
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema private; create schema auth;
    create function auth.jwt() returns jsonb language sql stable as $$ select current_setting('request.jwt.claims',true)::jsonb $$;
    create function auth.uid() returns uuid language sql stable as $$ select (auth.jwt()->>'sub')::uuid $$;
    create table public.profiles(id uuid primary key, is_active bool default true, must_change_password bool default false);
    create table auth.sessions(id uuid primary key, user_id uuid);
    create table public.notifications(id uuid primary key default gen_random_uuid(), recipient_id uuid not null, read_at timestamptz);
    insert into public.profiles(id) values ('${a}'), ('${b}');
    insert into auth.sessions values ('${session}', '${a}');
  `);
  await db.exec(await readFile(new URL('../ops/notification_push.sql', import.meta.url), 'utf8'));
  await db.exec(`set role authenticated; set request.jwt.claims = '{"sub":"${a}","session_id":"${session}"}';`);
  await db.query('select public.register_push_device($1,$2)', [installation, 'test-token']);
  await assert.rejects(db.query('select * from public.claim_push_deliveries()'), {code:'42501'});
  await db.exec('reset role');
  await db.query('insert into public.notifications(recipient_id) values ($1),($2)', [a,b]);
  await db.exec('set role service_role');
  const claim = async () => (await db.query('select * from public.claim_push_deliveries()')).rows;
  const jobs = await claim();
  assert.equal(jobs.length, 1);
  const [job] = jobs;
  assert.equal(job.token, 'test-token');
  assert.equal(job.attempts, 1);
  assert.deepEqual(await claim(), []);
  await db.query('select public.finish_push_delivery($1,$2,$3,$4)', [job.id,job.lease,60,null]);
  assert.deepEqual(await claim(), []);
  await db.exec('reset role; update private.push_deliveries set available_at = now(); set role service_role;');
  const [retry] = await claim();
  assert.equal(retry.attempts, 2);
  assert.notEqual(retry.lease, job.lease);
  await db.query('select public.finish_push_delivery($1,$2,$3,$4)', [retry.id,retry.lease,null,null]);
  assert.deepEqual(await claim(), []);
  await db.exec('reset role; set role authenticated;');
  await db.query('select public.unregister_push_device($1)', [installation]);
  await db.exec('reset role');
  assert.equal((await db.query('select * from private.push_devices')).rows.length, 0);
  console.log('Push queue SQL passed: role grants, recipient targeting, lease, retry, acknowledgment, and unregister.');
} finally {
  await db.close();
}

