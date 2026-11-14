-- Dry run for migrations/20261113090000_single_session_push_reasons.sql.
-- 1. Paste the migration WITHOUT its first "begin;" and last "commit;" where marked.
-- 2. Run the whole script in the SQL editor. It ends with ROLLBACK: nothing is kept.
-- It takes brief locks on attendance_correction_requests; run it at a quiet moment.
begin;

-- >>> paste the migration body here <<<

-- Expect: every signed-in account has exactly one active session.
select s.user_id, count(*) as sessions,
       count(*) filter (where not exists (
         select 1 from auth.sessions newer
         where newer.user_id = s.user_id and (newer.created_at, newer.id) > (s.created_at, s.id)
       )) as active
from auth.sessions s group by s.user_id;

-- Expect: one row, convalidated = false (history kept, new decisions checked).
select conname, convalidated from pg_constraint where conname = 'correction_decision_reason';

-- Expect: an error "A decision reason of 1-2000 characters is required".
do $$
declare v_id uuid;
begin
  select id into v_id from public.attendance_correction_requests where status = 'pending' limit 1;
  if v_id is null then raise notice 'No pending request to test with'; return; end if;
  begin
    update public.attendance_correction_requests
      set status = 'rejected', reviewed_at = now(),
          reviewed_by = (select id from public.profiles where role = 'admin' and id <> employee_id limit 1)
      where id = v_id;
    raise exception 'FAILED: a decision without a reason was accepted';
  exception when sqlstate '22023' then
    raise notice 'OK: decision without a reason refused';
  end;
end $$;

-- Expect: no client role can execute these.
select p.proname,
       has_function_privilege('anon', p.oid, 'execute') as anon,
       has_function_privilege('authenticated', p.oid, 'execute') as authenticated
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where (n.nspname, p.proname) in (('private','session_is_current'), ('public','claim_push_deliveries'));

rollback;
