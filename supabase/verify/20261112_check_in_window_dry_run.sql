-- Dry run for supabase/migrations/20261112090000_check_in_window.sql.
--
-- Paste the migration ABOVE the block below and run it all as ONE request
-- (one implicit transaction). The block always ends with an error, so
-- PostgreSQL rolls everything back, including the migration. The error text
-- is the report. Nothing persists.

do $$
declare
  admin_id uuid := '5f6e46af-236d-4c6e-b2c6-96f5c41e02fe';
  employee_id uuid := 'f7eb855e-82d9-4c0e-bcfd-b0ad28fdec66';
  out text := '';
  w record;
begin
  -- 1. Window arithmetic around the daylight-saving changes (Cairo is
  --    UTC+3 in summer, UTC+2 in winter).
  out := out || format(E'summer 2026-07-15 07:00 Cairo = %s UTC (expect 04:00)\n',
    to_char(('2026-07-15'::date + '07:00'::time) at time zone 'Africa/Cairo' at time zone 'UTC', 'HH24:MI'));
  out := out || format(E'winter 2026-11-15 07:00 Cairo = %s UTC (expect 05:00)\n',
    to_char(('2026-11-15'::date + '07:00'::time) at time zone 'Africa/Cairo' at time zone 'UTC', 'HH24:MI'));
  out := out || format(E'11:00 window close, winter = %s UTC (expect 09:00)\n',
    to_char(('2026-11-15'::date + '11:00'::time) at time zone 'Africa/Cairo' at time zone 'UTC', 'HH24:MI'));

  -- 2. Columns and constraint.
  out := out || format(E'schedules with 07:00-11:00: %s of %s\n',
    (select count(*) from public.work_schedules where checkin_opens = '07:00' and checkin_closes = '11:00'),
    (select count(*) from public.work_schedules));
  begin
    update public.work_schedules set checkin_opens = '12:00', checkin_closes = '11:00';
    out := out || E'opens after closes: ACCEPTED (BAD)\n';
  exception when check_violation then
    out := out || E'opens after closes: refused\n';
  end;

  -- 3. get_check_in_window as a real employee (authenticated role).
  perform set_config('request.jwt.claims', json_build_object('sub', employee_id, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  select * into w from public.get_check_in_window();
  out := out || format(E'employee window: date=%s working=%s opens=%s closes=%s (Cairo)\n',
    w.work_date, w.working_day,
    to_char(w.opens_at at time zone 'Africa/Cairo', 'HH24:MI'),
    to_char(w.closes_at at time zone 'Africa/Cairo', 'HH24:MI'));
  -- Same visibility as before the migration (own rows only).
  out := out || format(E'employee reads: records=%s schedules=%s\n',
    (select count(*) from public.attendance_records), (select count(*) from public.work_schedules));
  perform set_config('role', 'none', true);

  -- 4. Callers who aren't signed in can't call it.
  out := out || format(E'anon may call get_check_in_window: %s\n',
    has_function_privilege('anon', 'public.get_check_in_window()', 'execute'));
  out := out || format(E'authenticated may call get_check_in_window: %s\n',
    has_function_privilege('authenticated', 'public.get_check_in_window()', 'execute'));

  -- 5. check_in still compiles and keeps its grants.
  out := out || format(E'check_in mentions the window: %s; authenticated may call check_in: %s\n',
    (select pg_get_functiondef('public.check_in(double precision, double precision, double precision, text)'::regprocedure) like '%The check-in window has closed%'),
    has_function_privilege('authenticated', 'public.check_in(double precision, double precision, double precision, text)', 'execute'));

  raise exception 'DRY RUN (everything rolled back)%', E'\n' || out;
end $$;
