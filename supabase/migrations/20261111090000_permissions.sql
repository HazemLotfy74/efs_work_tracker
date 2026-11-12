-- Dynamic permissions (phase 1).                                   2026-11-11
--
-- NOT APPLIED (applied 2026-11-11 22:18 UTC, rolled back 22:22 UTC at the
-- owner's choice after verification found the missing EXECUTE grant now in
-- section 3). Apply only with the owner's explicit approval, after a dry run
-- in a transaction that rolls back (see docs/PERMISSIONS.md).
-- Rollback: supabase/backups/20261111_before_permissions.sql
--
-- Model (default deny):
--   permissions        catalog of capability codes
--   role_permissions   what a role always has      (admin -> every code)
--   user_permissions   extra grants for one person  (employees only)
--   effective = role default  OR  an individual grant
-- Everyday self-service (own attendance, check-in/out, own corrections and
-- cash requests) stays available to every active account, as today.
--
-- Behaviour on day one is unchanged: admins hold every code through their
-- role, employees hold none. Checks read the tables on every request, so a
-- revoked grant stops working immediately (nothing is cached in tokens).

-- 1. Tables ------------------------------------------------------------------

create table public.permissions (
  code text primary key check (code ~ '^[a-z]+\.[a-z_]+$'),
  category text not null check (category in ('attendance', 'cash', 'employees', 'reports')),
  description text not null,
  -- Only role admins may grant a sensitive code (it controls other people).
  sensitive boolean not null default false
);

create table public.role_permissions (
  role text not null check (role in ('employee', 'admin')),
  permission_code text not null references public.permissions (code) on delete cascade,
  primary key (role, permission_code)
);

create table public.user_permissions (
  -- `id` lets the existing private.audit_change() key the audit rows.
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  permission_code text not null references public.permissions (code) on delete cascade,
  granted_by uuid not null references public.profiles (id),
  granted_at timestamptz not null default clock_timestamp(),
  unique (user_id, permission_code),
  constraint user_permissions_no_self_grant check (granted_by <> user_id)
);
create index user_permissions_granted_by on public.user_permissions (granted_by);

insert into public.permissions (code, category, description, sensitive) values
  ('attendance.view_all', 'attendance', 'See every employee''s attendance days, locations and photos', false),
  ('attendance.view_correction_requests', 'attendance', 'See correction requests of all employees', false),
  ('attendance.approve_correction', 'attendance', 'Approve correction requests', false),
  ('attendance.reject_correction', 'attendance', 'Reject correction requests', false),
  ('attendance.edit', 'attendance', 'Correct the times of closed attendance days', false),
  ('attendance.edit_schedule', 'attendance', 'Assign schedules and change the grace period', false),
  ('cash.view_all', 'cash', 'See cash requests of all employees', false),
  ('cash.approve', 'cash', 'Approve cash requests', false),
  ('cash.reject', 'cash', 'Reject cash requests', false),
  ('employees.view', 'employees', 'See the employee list and profiles', false),
  ('employees.edit', 'employees', 'Activate and deactivate employee accounts', false),
  ('employees.manage_permissions', 'employees', 'Grant and revoke permissions', true),
  ('reports.view', 'reports', 'See HR report figures (reads all attendance)', false),
  ('reports.export', 'reports', 'Export the HR workbook', false),
  ('audit.view', 'employees', 'See the audit history', true);

insert into public.role_permissions (role, permission_code)
select 'admin', code from public.permissions;

-- 2. Checks ------------------------------------------------------------------

-- The signed-in, active, password-ready user holds p_code.
create function private.has_permission(p_code text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_active = true
      and p.must_change_password = false
      and (
        exists (select 1 from public.role_permissions r
                where r.role = p.role and r.permission_code = p_code)
        or exists (select 1 from public.user_permissions u
                   where u.user_id = p.id and u.permission_code = p_code)
      )
  );
$$;

create function private.has_any_permission(p_codes text[])
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select exists (select 1 from unnest(p_codes) as wanted (code)
                 where private.has_permission(wanted.code));
$$;

-- Like require_actor(), plus p_code. Returns the caller's id.
create function private.require_permission(p_code text)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  actor uuid;
begin
  actor := private.require_actor(false);
  if not private.has_permission(p_code) then
    raise exception 'You do not have permission for this action'
      using errcode = '42501';
  end if;
  return actor;
end;
$$;

-- 3. API for the app -----------------------------------------------------------

-- The caller's effective codes (empty for an unready account).
create function public.get_my_permissions()
returns setof text
language sql
stable
security definer
set search_path to ''
as $$
  select c.code
  from public.permissions c
  where private.is_active() and private.has_permission(c.code)
  order by c.code;
$$;

-- Every code, as it applies to p_user. Needs employees.manage_permissions.
create function public.admin_get_user_permissions(p_user uuid)
returns table (
  code text,
  category text,
  description text,
  sensitive boolean,
  from_role boolean,
  granted boolean,
  granted_by uuid,
  granted_at timestamptz,
  can_change boolean
)
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  actor uuid;
  actor_role text;
  target_role text;
begin
  actor := private.require_permission('employees.manage_permissions');
  select role into actor_role from public.profiles where id = actor;
  select role into target_role from public.profiles where id = p_user;
  if target_role is null then
    raise exception 'Employee profile not found' using errcode = '22023';
  end if;

  return query
  select c.code, c.category, c.description, c.sensitive,
         exists (select 1 from public.role_permissions r
                 where r.role = target_role and r.permission_code = c.code),
         u.id is not null,
         u.granted_by,
         u.granted_at,
         -- The same rules admin_set_user_permissions enforces.
         p_user <> actor
           and target_role = 'employee'
           and private.has_permission(c.code)
           and (not c.sensitive or actor_role = 'admin')
  from public.permissions c
  left join public.user_permissions u
    on u.user_id = p_user and u.permission_code = c.code
  order by c.category, c.code;
end;
$$;

-- Grants exactly p_codes (individual grants) to p_user, in one transaction.
-- Rules: caller holds employees.manage_permissions; never yourself; only
-- employee accounts (admins already hold everything); you can only grant
-- or revoke codes you hold; sensitive codes only by a role admin.
create function public.admin_set_user_permissions(p_user uuid, p_codes text[])
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  actor uuid;
  actor_role text;
  target public.profiles%rowtype;
  changed text;
begin
  actor := private.require_permission('employees.manage_permissions');
  select role into actor_role from public.profiles where id = actor;

  if p_codes is null then
    raise exception 'A list of permissions is required' using errcode = '22023';
  end if;

  select * into target from public.profiles where id = p_user for update;
  if not found then
    raise exception 'Employee profile not found' using errcode = '22023';
  end if;
  if target.id = actor then
    raise exception 'You cannot change your own permissions' using errcode = '42501';
  end if;
  if target.role <> 'employee' then
    raise exception 'Permissions can only be granted to employee accounts' using errcode = '42501';
  end if;
  -- Aliases are qualified everywhere: an unqualified "code" would bind to
  -- permissions.code and make these checks always pass.
  if exists (select 1 from unnest(p_codes) as wanted (code)
             where not exists (select 1 from public.permissions c
                               where c.code = wanted.code)) then
    raise exception 'Unknown permission' using errcode = '22023';
  end if;

  -- Every code that changes, added or removed, must be one the caller may
  -- delegate.
  for changed in
    select wanted.code from unnest(p_codes) as wanted (code)
    where not exists (select 1 from public.user_permissions u
                      where u.user_id = p_user and u.permission_code = wanted.code)
    union
    select u.permission_code from public.user_permissions u
    where u.user_id = p_user and not (u.permission_code = any (p_codes))
  loop
    if not private.has_permission(changed) then
      raise exception 'You cannot delegate a permission you do not hold' using errcode = '42501';
    end if;
    if actor_role <> 'admin'
       and (select sensitive from public.permissions where code = changed) then
      raise exception 'Only an administrator can change this permission' using errcode = '42501';
    end if;
  end loop;

  delete from public.user_permissions u
  where u.user_id = p_user and not (u.permission_code = any (p_codes));

  insert into public.user_permissions (user_id, permission_code, granted_by)
  select distinct p_user, wanted.code, actor from unnest(p_codes) as wanted (code)
  on conflict (user_id, permission_code) do nothing;
end;
$$;

revoke all on function private.has_permission(text) from public, anon;
revoke all on function private.has_any_permission(text[]) from public, anon;
revoke all on function private.require_permission(text) from public, anon;
revoke all on function public.get_my_permissions() from public, anon;
revoke all on function public.admin_get_user_permissions(uuid) from public, anon;
revoke all on function public.admin_set_user_permissions(uuid, text[]) from public, anon;
grant execute on function public.get_my_permissions() to authenticated;
grant execute on function public.admin_get_user_permissions(uuid) to authenticated;
grant execute on function public.admin_set_user_permissions(uuid, text[]) to authenticated;
-- The read policies below run these checks as the signed-in user. Without
-- this grant every signed-in read failed (42501) — found on 2026-11-11.
-- Same exposure as private.is_admin(): they only answer for auth.uid().
grant execute on function private.has_permission(text) to authenticated;
grant execute on function private.has_any_permission(text[]) to authenticated;

-- 4. RLS: read-only, like every other table ------------------------------------

alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_permissions enable row level security;

create policy permissions_read on public.permissions
  for select to authenticated using ((select private.is_active()));
create policy role_permissions_read on public.role_permissions
  for select to authenticated using ((select private.is_active()));
create policy user_permissions_read on public.user_permissions
  for select to authenticated using (
    (select private.is_active())
    and (user_id = (select auth.uid())
         or (select private.has_permission('employees.manage_permissions')))
  );

revoke insert, update, delete, truncate on public.permissions, public.role_permissions,
  public.user_permissions from anon, authenticated;

create trigger audit_change after insert or update or delete on public.user_permissions
  for each row execute function private.audit_change();
create trigger audit_change after insert or update or delete on public.role_permissions
  for each row execute function private.audit_change();

-- 5. Existing read policies: is_admin() -> permissions ------------------------
-- Admins keep exactly what they had (their role holds every code).

alter policy profile_read on public.profiles using (
  (select private.is_active())
  and (id = (select auth.uid())
       or (select private.has_any_permission(array[
         'employees.view', 'attendance.view_all', 'attendance.view_correction_requests',
         'cash.view_all', 'reports.view', 'employees.manage_permissions'])))
);

alter policy attendance_read on public.attendance_records using (
  (select private.is_active())
  and (employee_id = (select auth.uid())
       or (select private.has_any_permission(array[
         'attendance.view_all', 'attendance.view_correction_requests', 'reports.view'])))
);

alter policy event_read on public.attendance_events using (
  (select private.is_active())
  and exists (
    select 1 from public.attendance_records attendance
    where attendance.id = attendance_events.attendance_id
      and (attendance.employee_id = (select auth.uid())
           or (select private.has_any_permission(array[
             'attendance.view_all', 'attendance.view_correction_requests']))))
);

alter policy correction_read on public.attendance_correction_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid())
       or (select private.has_any_permission(array[
         'attendance.view_correction_requests', 'attendance.view_all', 'reports.view'])))
);

alter policy advance_read on public.expense_advance_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid())
       or (select private.has_permission('cash.view_all')))
);

alter policy overtime_read on public.overtime_requests using (
  (select private.is_active())
  and (employee_id = (select auth.uid())
       or (select private.has_permission('attendance.view_all')))
);

alter policy audit_read on public.audit_logs using (
  (select private.has_permission('audit.view'))
);

alter policy attendance_selfie_read on storage.objects using (
  bucket_id = 'attendance-evidence'
  and (select private.is_active())
  and (
    (owner_id = ((select auth.uid()))::text
     and split_part(name, '/', 1) = ((select auth.uid()))::text)
    or ((select private.has_any_permission(array[
          'attendance.view_all', 'attendance.view_correction_requests']))
        and exists (select 1 from public.attendance_events event
                    where event.selfie_path = objects.name))
  )
);

-- 6. Existing write functions: only the authorization line changes -----------

create or replace function public.admin_assign_schedule(p_employee_id uuid, p_schedule_id uuid)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
begin
  perform private.require_permission('attendance.edit_schedule');

  -- Check and lock the selected schedule during assignment.
  perform 1
  from public.work_schedules
  where id = p_schedule_id
  for share;

  if not found then
    raise exception 'Schedule not found'
      using errcode = '22023';
  end if;

  update public.profiles
  set schedule_id = p_schedule_id
  where id = p_employee_id;

  if not found then
    raise exception 'Employee profile not found'
      using errcode = '22023';
  end if;
end;
$function$;

create or replace function public.admin_set_grace(p_schedule_id uuid, p_minutes integer)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
begin
  perform private.require_permission('attendance.edit_schedule');

  if p_minutes is null
     or p_minutes not between 0 and 120 then
    raise exception
      'Grace must be between 0 and 120 whole minutes'
      using errcode = '22023';
  end if;

  update public.work_schedules
  set grace_minutes = p_minutes
  where id = p_schedule_id;

  if not found then
    raise exception 'Schedule not found'
      using errcode = '22023';
  end if;
end;
$function$;

create or replace function public.admin_set_employee_active(p_employee_id uuid, p_is_active boolean)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  admin_uuid uuid;
  employee public.profiles%rowtype;
begin
  admin_uuid := private.require_permission('employees.edit');

  if p_is_active is null then
    raise exception 'Active status must be true or false'
      using errcode = '22023';
  end if;

  -- Find and lock the employee profile.
  select *
  into employee
  from public.profiles
  where id = p_employee_id
  for update;

  if not found then
    raise exception 'Employee profile not found'
      using errcode = '22023';
  end if;

  -- Admin account management remains operator-controlled.
  if employee.role <> 'employee'
     or employee.id = admin_uuid then
    raise exception
      'This operation is only for employee accounts'
      using errcode = '42501';
  end if;

  update public.profiles
  set is_active = p_is_active
  where id = employee.id
    and is_active is distinct from p_is_active;
end;
$function$;

create or replace function public.admin_correct_attendance(
  p_attendance_id uuid, p_checkin timestamptz, p_checkout timestamptz, p_reason text)
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
  admin_uuid := private.require_permission('attendance.edit');

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
    employee_id, attendance_id, proposed_checkin, proposed_checkout,
    base_updated_at, reason, status, reviewed_by, reviewed_at, review_note
  )
  values (
    attendance.employee_id, attendance.id, p_checkin, p_checkout,
    attendance.updated_at, correction_reason, 'approved', admin_uuid,
    clock_timestamp(), correction_reason
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

create or replace function public.review_request(
  p_kind text, p_request_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  admin_uuid uuid;
  request_employee uuid;
  request_status text;
  decision text;
  correction public.attendance_correction_requests%rowtype;
  attendance public.attendance_records%rowtype;
begin
  if p_approve is null then
    raise exception 'An approval decision is required'
      using errcode = '22023';
  end if;

  -- Each decision needs its own permission; overtime stays admin-only.
  if p_kind = 'expense_advance' then
    admin_uuid := private.require_permission(
      case when p_approve then 'cash.approve' else 'cash.reject' end);
  elsif p_kind = 'correction' then
    admin_uuid := private.require_permission(
      case when p_approve then 'attendance.approve_correction'
           else 'attendance.reject_correction' end);
  elsif p_kind = 'overtime' then
    admin_uuid := private.require_actor(true);
  else
    raise exception 'Unknown request kind'
      using errcode = '22023';
  end if;

  if length(p_note) > 2000 then
    raise exception 'Review note cannot exceed 2000 characters'
      using errcode = '22023';
  end if;

  decision := case when p_approve then 'approved' else 'rejected' end;

  -- Lock the selected ticket; another reviewer must wait for this decision.
  if p_kind = 'overtime' then
    select employee_id, status
    into request_employee, request_status
    from public.overtime_requests
    where id = p_request_id
    for update;

  elsif p_kind = 'expense_advance' then
    select employee_id, status
    into request_employee, request_status
    from public.expense_advance_requests
    where id = p_request_id
    for update;

  else
    select * into correction
    from public.attendance_correction_requests
    where id = p_request_id
    for update;

    request_employee := correction.employee_id;
    request_status := correction.status;
  end if;

  if request_employee is null then
    raise exception 'Request not found'
      using errcode = '22023';
  end if;

  if request_employee = admin_uuid then
    raise exception 'You cannot review your own request'
      using errcode = '42501';
  end if;

  if request_status <> 'pending' then
    raise exception 'This request has already been reviewed';
  end if;

  if p_kind = 'overtime' then
    update public.overtime_requests
    set status = decision,
        reviewed_by = admin_uuid,
        reviewed_at = clock_timestamp(),
        review_note = nullif(btrim(p_note), '')
    where id = p_request_id;

  elsif p_kind = 'expense_advance' then
    update public.expense_advance_requests
    set status = decision,
        reviewed_by = admin_uuid,
        reviewed_at = clock_timestamp(),
        review_note = nullif(btrim(p_note), '')
    where id = p_request_id;

  else
    if p_approve then
      select * into attendance
      from public.attendance_records
      where id = correction.attendance_id
      for update;

      if not found then
        raise exception 'Attendance record not found';
      end if;

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
             and correction.proposed_checkout = attendance.auto_close_deadline)
         )) then
        raise exception 'Proposed correction times are outside the allowed attendance period'
          using errcode = '22023';
      end if;

      -- Never overwrite actual times, automatic-close flags or evidence events.
      update public.attendance_records
      set effective_checkin = correction.proposed_checkin,
          effective_checkout = correction.proposed_checkout,
          has_correction = true
      where id = attendance.id;
    end if;

    update public.attendance_correction_requests
    set status = decision,
        reviewed_by = admin_uuid,
        reviewed_at = clock_timestamp(),
        review_note = nullif(btrim(p_note), '')
    where id = p_request_id;
  end if;
end;
$function$;
