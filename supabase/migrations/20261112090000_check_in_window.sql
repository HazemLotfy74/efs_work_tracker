-- Daily check-in window 07:00–11:00 (Africa/Cairo).               2026-11-12
--
-- NOT APPLIED. Apply only with the owner's explicit approval, after the dry
-- run in supabase/verify/20261112_check_in_window_dry_run.sql (one
-- transaction that always rolls back).
-- Rollback: supabase/backups/20261112_before_check_in_window.sql
--
-- Today check_in accepts check-ins from the shift start (08:00) until the
-- shift end (16:00). New rule: from checkin_opens until checkin_closes of
-- the employee's schedule, in the schedule's timezone, by the server clock:
--   07:00:00 <= check-in < 11:00:00   (11:00 exactly is refused)
-- Everything else in check_in is unchanged (lock, auto-close, schedule,
-- GPS, selfie, one record per day). Lateness is still measured from the
-- shift start with the grace period (late_minutes is clamped at 0), and the
-- 8 regular hours still start at the actual check-in. Check-out, overtime
-- and the midnight auto-close are untouched.
-- Timezone: `(date + time) at time zone 'Africa/Cairo'` uses the IANA rules
-- of that date, so daylight saving changes are handled by PostgreSQL.

-- 1. The window, per schedule.
alter table public.work_schedules
  add column checkin_opens time not null default '07:00',
  add column checkin_closes time not null default '11:00',
  add constraint work_schedules_check_in_window check (checkin_opens < checkin_closes);

-- 2. Today's window and the server clock, for the app's button (and to
--    correct a wrong phone clock). Read-only; only the caller's own schedule.
create function public.get_check_in_window()
returns table (
  server_now timestamptz,
  work_date date,
  working_day boolean,
  opens_at timestamptz,
  closes_at timestamptz
)
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  employee_uuid uuid;
  schedule public.work_schedules%rowtype;
  today date;
begin
  employee_uuid := private.require_actor(false);
  select s.* into schedule
  from public.work_schedules s
  join public.profiles p on p.schedule_id = s.id
  where p.id = employee_uuid;
  if not found then
    raise exception 'No assigned work schedule';
  end if;
  server_now := clock_timestamp();
  today := (server_now at time zone schedule.timezone)::date;
  work_date := today;
  working_day := exists (
    select 1 from public.schedule_days d
    where d.schedule_id = schedule.id and d.weekday = extract(dow from today)::integer);
  opens_at := (today + schedule.checkin_opens) at time zone schedule.timezone;
  closes_at := (today + schedule.checkin_closes) at time zone schedule.timezone;
  return next;
end;
$$;

revoke all on function public.get_check_in_window() from public, anon;
grant execute on function public.get_check_in_window() to authenticated;

-- 3. check_in: the window replaces the shift-start / shift-end checks.
create or replace function public.check_in(
  p_latitude double precision, p_longitude double precision,
  p_accuracy_m double precision, p_selfie_path text)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  employee_uuid uuid;
  schedule public.work_schedules%rowtype;
  working_day public.schedule_days%rowtype;

  checkin_time timestamptz;
  working_date date;
  shift_start timestamptz;
  shift_end timestamptz;
  window_opens timestamptz;
  window_closes timestamptz;

  attendance_uuid uuid;
begin
  -- 1. Verify the caller's identity and account readiness.
  employee_uuid := private.require_actor();

  -- 2. Serialize check-in attempts for the same employee.
  perform pg_advisory_xact_lock(
    hashtextextended(employee_uuid::text, 0)
  );

  -- 3. Close any overdue attendance for this employee.
  perform private.close_due(employee_uuid);

  -- 4. Read and lock the assigned schedule.
  select s.*
  into schedule
  from public.work_schedules as s
  join public.profiles as p
    on p.schedule_id = s.id
  where p.id = employee_uuid
  for share of s;

  if not found then
    raise exception 'No assigned work schedule';
  end if;

  checkin_time := clock_timestamp();

  working_date :=
    (checkin_time at time zone schedule.timezone)::date;

  -- 5. Find today's shift in the schedule.
  select *
  into working_day
  from public.schedule_days
  where schedule_id = schedule.id
    and weekday = extract(dow from working_date)::integer
  for share;

  if not found then
    raise exception 'There is no scheduled shift today';
  end if;

  -- 6. Require valid GPS values.
  if p_latitude is null
     or p_longitude is null
     or p_accuracy_m is null
     or p_latitude not between -90 and 90
     or p_longitude not between -180 and 180
     or p_accuracy_m not between 0 and 10000 then

    raise exception 'Valid GPS coordinates and accuracy are required'
      using errcode = '22023';
  end if;

  -- 7. Verify the uploaded selfie.
  perform private.assert_selfie(
    employee_uuid,
    p_selfie_path
  );

  -- Refresh server time after validation and any lock waits.
  checkin_time := clock_timestamp();

  if (checkin_time at time zone schedule.timezone)::date
      <> working_date then
    raise exception 'The working date changed; please retry';
  end if;

  shift_start :=
    (working_date + working_day.starts_at)
      at time zone schedule.timezone;

  shift_end :=
    (working_date + working_day.ends_at)
      at time zone schedule.timezone;

  window_opens :=
    (working_date + schedule.checkin_opens)
      at time zone schedule.timezone;

  window_closes :=
    (working_date + schedule.checkin_closes)
      at time zone schedule.timezone;

  -- The daily check-in window, by the server clock.
  if checkin_time < window_opens then
    raise exception 'Check-in opens at %', to_char(schedule.checkin_opens, 'HH24:MI')
      using errcode = '22023';
  end if;

  if checkin_time >= window_closes then
    raise exception 'The check-in window has closed'
      using errcode = '22023';
  end if;

  -- Kept: a record must start before its shift ends (table constraint).
  if checkin_time >= shift_end then
    raise exception 'The shift has ended; check-in is closed';
  end if;

  -- 8. Create the daily attendance record.
  insert into public.attendance_records (
    employee_id,
    work_date,
    schedule_id,
    timezone,
    scheduled_start,
    scheduled_end,
    grace_minutes,
    actual_checkin,
    effective_checkin
  )
  values (
    employee_uuid,
    working_date,
    schedule.id,
    schedule.timezone,
    shift_start,
    shift_end,
    schedule.grace_minutes,
    checkin_time,
    checkin_time
  )
  returning id into attendance_uuid;

  -- 9. Save the real check-in event and its evidence.
  insert into public.attendance_events (
    attendance_id,
    event_type,
    occurred_at,
    latitude,
    longitude,
    accuracy_m,
    selfie_path
  )
  values (
    attendance_uuid,
    'check_in',
    checkin_time,
    p_latitude,
    p_longitude,
    p_accuracy_m,
    p_selfie_path
  );

  return attendance_uuid;
end;
$function$;
