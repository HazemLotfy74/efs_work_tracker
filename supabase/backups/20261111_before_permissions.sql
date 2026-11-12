-- Rollback for supabase/migrations/20261111090000_permissions.sql
--
-- Restores the authorization captured from the live database on 2026-11-11:
-- every read policy and admin function checks the admin role again
-- (private.is_admin() / private.require_actor(true)). Run as one transaction.
-- Individual grants are lost (they are kept in audit_logs).

begin;

-- 1. Read policies, as they were.
alter policy profile_read on public.profiles using (
  (select private.is_active())
  and (id = (select auth.uid()) or (select private.is_admin())));
alter policy attendance_read on public.attendance_records using (
  (select private.is_active())
  and (employee_id = (select auth.uid()) or (select private.is_admin())));
alter policy event_read on public.attendance_events using (
  (select private.is_active())
  and exists (select 1 from public.attendance_records attendance
              where attendance.id = attendance_events.attendance_id
                and (attendance.employee_id = (select auth.uid())
                     or (select private.is_admin()))));
alter policy correction_read on public.attendance_correction_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid()) or (select private.is_admin())));
alter policy advance_read on public.expense_advance_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid()) or (select private.is_admin())));
alter policy overtime_read on public.overtime_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid()) or (select private.is_admin())));
alter policy audit_read on public.audit_logs using ((select private.is_admin()));
alter policy attendance_selfie_read on storage.objects using (
  bucket_id = 'attendance-evidence'
  and (select private.is_active())
  and ((owner_id = ((select auth.uid()))::text
        and split_part(name, '/', 1) = ((select auth.uid()))::text)
       or ((select private.is_admin())
           and exists (select 1 from public.attendance_events event
                       where event.selfie_path = objects.name))));

-- 2. Admin functions: the authorization line back to require_actor(true).
--    Bodies are otherwise identical to the migration's (and the live
--    definitions they replaced).
create or replace function public.admin_assign_schedule(p_employee_id uuid, p_schedule_id uuid)
returns void language plpgsql security definer set search_path to '' as $function$
begin
  perform private.require_actor(true);
  perform 1 from public.work_schedules where id = p_schedule_id for share;
  if not found then
    raise exception 'Schedule not found' using errcode = '22023';
  end if;
  update public.profiles set schedule_id = p_schedule_id where id = p_employee_id;
  if not found then
    raise exception 'Employee profile not found' using errcode = '22023';
  end if;
end;
$function$;

create or replace function public.admin_set_grace(p_schedule_id uuid, p_minutes integer)
returns void language plpgsql security definer set search_path to '' as $function$
begin
  perform private.require_actor(true);
  if p_minutes is null or p_minutes not between 0 and 120 then
    raise exception 'Grace must be between 0 and 120 whole minutes' using errcode = '22023';
  end if;
  update public.work_schedules set grace_minutes = p_minutes where id = p_schedule_id;
  if not found then
    raise exception 'Schedule not found' using errcode = '22023';
  end if;
end;
$function$;

create or replace function public.admin_set_employee_active(p_employee_id uuid, p_is_active boolean)
returns void language plpgsql security definer set search_path to '' as $function$
declare
  admin_uuid uuid;
  employee public.profiles%rowtype;
begin
  admin_uuid := private.require_actor(true);
  if p_is_active is null then
    raise exception 'Active status must be true or false' using errcode = '22023';
  end if;
  select * into employee from public.profiles where id = p_employee_id for update;
  if not found then
    raise exception 'Employee profile not found' using errcode = '22023';
  end if;
  if employee.role <> 'employee' or employee.id = admin_uuid then
    raise exception 'This operation is only for employee accounts' using errcode = '42501';
  end if;
  update public.profiles set is_active = p_is_active
  where id = employee.id and is_active is distinct from p_is_active;
end;
$function$;

-- review_request, as it was:
create or replace function public.review_request(
  p_kind text, p_request_id uuid, p_approve boolean, p_note text default null)
returns void language plpgsql security definer set search_path to '' as $function$
declare
  admin_uuid uuid;
  request_employee uuid;
  request_status text;
  decision text;
  correction public.attendance_correction_requests%rowtype;
  attendance public.attendance_records%rowtype;
begin
  admin_uuid := private.require_actor(true);
  if p_approve is null then
    raise exception 'An approval decision is required' using errcode = '22023';
  end if;
  if length(p_note) > 2000 then
    raise exception 'Review note cannot exceed 2000 characters' using errcode = '22023';
  end if;
  decision := case when p_approve then 'approved' else 'rejected' end;
  if p_kind = 'overtime' then
    select employee_id, status into request_employee, request_status
    from public.overtime_requests where id = p_request_id for update;
  elsif p_kind = 'expense_advance' then
    select employee_id, status into request_employee, request_status
    from public.expense_advance_requests where id = p_request_id for update;
  elsif p_kind = 'correction' then
    select * into correction from public.attendance_correction_requests
    where id = p_request_id for update;
    request_employee := correction.employee_id;
    request_status := correction.status;
  else
    raise exception 'Unknown request kind' using errcode = '22023';
  end if;
  if request_employee is null then
    raise exception 'Request not found' using errcode = '22023';
  end if;
  if request_employee = admin_uuid then
    raise exception 'You cannot review your own request' using errcode = '42501';
  end if;
  if request_status <> 'pending' then
    raise exception 'This request has already been reviewed';
  end if;
  if p_kind = 'overtime' then
    update public.overtime_requests set status = decision, reviewed_by = admin_uuid,
      reviewed_at = clock_timestamp(), review_note = nullif(btrim(p_note), '')
    where id = p_request_id;
  elsif p_kind = 'expense_advance' then
    update public.expense_advance_requests set status = decision, reviewed_by = admin_uuid,
      reviewed_at = clock_timestamp(), review_note = nullif(btrim(p_note), '')
    where id = p_request_id;
  else
    if p_approve then
      select * into attendance from public.attendance_records
      where id = correction.attendance_id for update;
      if not found then raise exception 'Attendance record not found'; end if;
      if attendance.employee_id <> request_employee then
        raise exception 'Correction does not belong to this employee';
      end if;
      if attendance.updated_at is distinct from correction.base_updated_at then
        raise exception 'Attendance changed; reject this request and ask the employee to resubmit';
      end if;
      if attendance.actual_checkout is null and not attendance.auto_closed then
        raise exception 'Attendance must be closed before correction approval';
      end if;
      if correction.proposed_checkin is null
         or (correction.proposed_checkin at time zone attendance.timezone)::date <> attendance.work_date
         or correction.proposed_checkin >= attendance.scheduled_end
         or (correction.proposed_checkout is not null and (
           correction.proposed_checkout < correction.proposed_checkin
           or correction.proposed_checkout > attendance.auto_close_deadline
           or (attendance.auto_close_policy = 'midnight'
             and correction.proposed_checkout = attendance.auto_close_deadline))) then
        raise exception 'Proposed correction times are outside the allowed attendance period'
          using errcode = '22023';
      end if;
      update public.attendance_records
      set effective_checkin = correction.proposed_checkin,
          effective_checkout = correction.proposed_checkout,
          has_correction = true
      where id = attendance.id;
    end if;
    update public.attendance_correction_requests set status = decision, reviewed_by = admin_uuid,
      reviewed_at = clock_timestamp(), review_note = nullif(btrim(p_note), '')
    where id = p_request_id;
  end if;
end;
$function$;

-- admin_correct_attendance, from 20261102090000_admin_correct_attendance.sql:
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

-- 3. New objects. Tables first: user_permissions_read depends on
--    private.has_permission.
drop table public.user_permissions;
drop table public.role_permissions;
drop table public.permissions;
drop function public.admin_set_user_permissions(uuid, text[]);
drop function public.admin_get_user_permissions(uuid);
drop function public.get_my_permissions();
drop function private.require_permission(text);
drop function private.has_any_permission(text[]);
drop function private.has_permission(text);

commit;
