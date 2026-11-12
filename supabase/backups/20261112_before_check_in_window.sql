-- Rollback for supabase/migrations/20261112090000_check_in_window.sql.
-- Restores check_in as captured from the live database on 2026-11-11
-- (check-in from the shift start until the shift end) and removes the
-- window columns and function. Run as one transaction.

begin;

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

  if checkin_time < shift_start then
    raise exception 'Check-in opens at the scheduled shift start'
      using errcode = '22023';
  end if;

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

drop function public.get_check_in_window();
alter table public.work_schedules
  drop constraint work_schedules_check_in_window,
  drop column checkin_closes,
  drop column checkin_opens;

commit;
