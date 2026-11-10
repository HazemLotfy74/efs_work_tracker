-- Admin attendance correction (backward-compatible: adds one function only).
--
-- An admin sets the confirmed check-in / check-out of a closed attendance day,
-- e.g. the employee arrived at 08:00 but checked in at 08:30.
--
-- Nothing is overwritten:
--   * actual_checkin / actual_checkout and the evidence events stay as recorded;
--   * the corrected times go to effective_checkin / effective_checkout with
--     has_correction = true (the columns approved correction requests use);
--   * the decision is stored as an APPROVED attendance_correction_requests row
--     (reason, reviewed_by = the admin, reviewed_at), so it appears with the
--     employee's other corrections;
--   * the existing audit_change triggers log both rows with old and new values
--     and the admin as actor.
--
-- The same time rules as review_request's correction approval apply.
-- Run in the SQL editor (or `supabase db push`). Not applied by the app team.

create or replace function public.admin_correct_attendance(
  p_attendance_id uuid,
  p_checkin timestamptz,
  p_checkout timestamptz,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  admin_uuid uuid;
  attendance public.attendance_records%rowtype;
  correction_reason text;
  request_uuid uuid;
begin
  -- Active, password-ready admin; the role comes from profiles, never the client.
  admin_uuid := private.require_actor(true);

  correction_reason := btrim(p_reason);
  if coalesce(length(correction_reason), 0) not between 1 and 2000 then
    raise exception 'A reason of 1-2000 characters is required'
      using errcode = '22023';
  end if;

  select *
  into attendance
  from public.attendance_records
  where id = p_attendance_id
  for update;

  if not found then
    raise exception 'Attendance record not found'
      using errcode = '22023';
  end if;

  -- Same separation of duties as review_request: no self-approval.
  if attendance.employee_id = admin_uuid then
    raise exception 'You cannot correct your own attendance'
      using errcode = '42501';
  end if;

  if attendance.actual_checkout is null and not attendance.auto_closed then
    raise exception 'Attendance must be closed before correction'
      using errcode = '22023';
  end if;

  if p_checkin is null
     or p_checkout is null
     or (p_checkin at time zone attendance.timezone)::date <> attendance.work_date
     or p_checkin >= attendance.scheduled_end
     or p_checkout < p_checkin
     or p_checkout > attendance.auto_close_deadline
     or (attendance.auto_close_policy = 'midnight'
         and p_checkout = attendance.auto_close_deadline) then
    raise exception 'Proposed correction times are outside the allowed attendance period'
      using errcode = '22023';
  end if;

  if attendance.has_correction
     and p_checkin = attendance.effective_checkin
     and p_checkout is not distinct from attendance.effective_checkout then
    raise exception 'No change was requested'
      using errcode = '22023';
  end if;

  -- Don't silently bypass the employee's own request: review it first.
  if exists (
    select 1
    from public.attendance_correction_requests
    where attendance_id = attendance.id
      and status = 'pending'
  ) then
    raise exception 'A pending correction already exists for this attendance'
      using errcode = '23505';
  end if;

  insert into public.attendance_correction_requests (
    employee_id,
    attendance_id,
    proposed_checkin,
    proposed_checkout,
    base_updated_at,
    reason,
    status,
    reviewed_by,
    reviewed_at,
    review_note
  )
  values (
    attendance.employee_id,
    attendance.id,
    p_checkin,
    p_checkout,
    attendance.updated_at,
    correction_reason,
    'approved',
    admin_uuid,
    clock_timestamp(),
    correction_reason
  )
  returning id into request_uuid;

  update public.attendance_records
  set effective_checkin = p_checkin,
      effective_checkout = p_checkout,
      has_correction = true
  where id = attendance.id;

  return request_uuid;
end;
$function$;

revoke all on function public.admin_correct_attendance(uuid, timestamptz, timestamptz, text)
  from public, anon;
grant execute on function public.admin_correct_attendance(uuid, timestamptz, timestamptz, text)
  to authenticated;

-- Rollback:
-- drop function if exists public.admin_correct_attendance(uuid, timestamptz, timestamptz, text);
