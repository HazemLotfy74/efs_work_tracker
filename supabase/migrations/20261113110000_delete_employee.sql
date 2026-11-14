-- Permanent deletion of an employee account, by an administrator.
--
-- NOT APPLIED AUTOMATICALLY. Review, test on a copy if you can, then run in the
-- SQL editor and deploy functions/employee-accounts (action "delete_employee").
-- Rollback: supabase/backups/20261113_delete_employee_rollback.sql.
--
-- This file itself deletes nothing. It adds two nullable columns, one trigger
-- and one function that only the server (service_role) can call.
--
-- What deleting an employee does (public.backend_delete_employee):
--   always removed : sign-in sessions and refresh tokens, registered phones and
--                    queued pushes, the employee's notifications, any pending
--                    login-email change, the reviewer permissions, the phone
--                    number; requests assigned to the employee for review go
--                    back to the admins; the employee's own pending requests
--                    are closed as rejected ("Employee account deleted").
--   then, either   : nothing else refers to the account -> the profile row is
--                    deleted ("hard"), and the Edge Function deletes the Auth
--                    user;
--   or             : attendance, requests, decisions or audit entries refer to
--                    it (every such foreign key is ON DELETE RESTRICT, and
--                    attendance evidence and the audit log are append-only) ->
--                    the profile stays as a locked record with name, username
--                    and employee code only ("anonymized": no phone, no
--                    permissions, no access), and the Edge Function soft-deletes
--                    the Auth user, which destroys the login for good.
-- Kept in the second case, and why: attendance days and their evidence, cash,
-- overtime and correction requests with their decisions, and the audit log:
-- payroll, accounting and audit history of the company. The name and employee
-- code stay with them so that history still says whose it was.
begin;

alter table public.profiles
  add column deleted_at timestamptz,
  add column deleted_by uuid references public.profiles(id) on delete restrict;
create index profiles_deleted_by_idx on public.profiles (deleted_by)
  where deleted_by is not null;

-- A deleted account can never be changed again: not re-activated, not given a
-- permission, not edited.
create function private.protect_deleted_profile() returns trigger
language plpgsql set search_path = '' as $$
begin
  if old.deleted_at is not null then
    raise exception 'This account was deleted and cannot be changed'
      using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.protect_deleted_profile() from public, anon, authenticated;
create trigger protect_deleted_profile
  before update on public.profiles
  for each row execute function private.protect_deleted_profile();

-- Called only by the employee-accounts Edge Function, which has verified the
-- caller's token with Supabase Auth and passes the caller's id as p_actor.
-- Returns {"mode": "hard" | "anonymized" | "gone"}; the function then removes
-- the Auth user accordingly. Safe to repeat: a second call changes nothing.
create function public.backend_delete_employee(p_actor uuid, p_employee_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  target public.profiles%rowtype;
  prior_actor text := current_setting('app.account_actor', true);
  prior_event text := current_setting('app.account_event', true);
  v_mode text;
begin
  -- An active admin with a completed password change, checked in the database.
  perform private.require_backend_admin(p_actor);

  if p_employee_id is null then
    raise exception 'An employee is required' using errcode = '22023';
  end if;
  if p_employee_id = p_actor then
    raise exception 'You cannot delete your own account' using errcode = '42501';
  end if;

  select * into target from public.profiles where id = p_employee_id for update;
  if not found then
    return jsonb_build_object('mode', 'gone');
  end if;
  -- Admin accounts are never deleted from the app: this is what keeps the last
  -- administrator, and any system account, out of reach.
  if target.role <> 'employee' then
    raise exception 'Administrator accounts cannot be deleted from the app'
      using errcode = '42501';
  end if;
  if target.deleted_at is not null then
    return jsonb_build_object('mode', 'anonymized');
  end if;

  perform set_config('app.account_actor', p_actor::text, true);
  perform set_config('app.account_event', 'employee_deleted', true);

  -- Access: every session ends now (refresh tokens go with them).
  delete from auth.sessions s where s.user_id = p_employee_id;
  delete from private.push_devices d where d.user_id = p_employee_id;
  delete from private.employee_email_changes c where c.employee_id = p_employee_id;

  -- Requests waiting for this employee's decision return to the admins.
  update public.expense_advance_requests r set assigned_reviewer_id = null
    where r.assigned_reviewer_id = p_employee_id and r.status = 'pending';
  update public.overtime_requests r set assigned_reviewer_id = null
    where r.assigned_reviewer_id = p_employee_id and r.status = 'pending';
  update public.attendance_correction_requests r set assigned_reviewer_id = null
    where r.assigned_reviewer_id = p_employee_id and r.status = 'pending';

  -- The employee's own open requests are closed, not left pending forever.
  update public.expense_advance_requests r
    set status = 'rejected', reviewed_by = p_actor, reviewed_at = clock_timestamp(),
        review_note = 'Employee account deleted'
    where r.employee_id = p_employee_id and r.status = 'pending';
  update public.overtime_requests r
    set status = 'rejected', reviewed_by = p_actor, reviewed_at = clock_timestamp(),
        review_note = 'Employee account deleted'
    where r.employee_id = p_employee_id and r.status = 'pending';
  update public.attendance_correction_requests r
    set status = 'rejected', reviewed_by = p_actor, reviewed_at = clock_timestamp(),
        review_note = 'Employee account deleted'
    where r.employee_id = p_employee_id and r.status = 'pending';

  -- After the updates above, which notify the employee one last time.
  delete from public.notifications n where n.recipient_id = p_employee_id;

  -- Nothing refers to the account: remove it entirely. Otherwise the foreign
  -- keys refuse, the delete alone is undone, and the record is locked instead.
  begin
    delete from public.profiles p where p.id = p_employee_id;
    v_mode := 'hard';
  exception when foreign_key_violation or restrict_violation then
    update public.profiles p
      set is_active = false, must_change_password = true, phone = null,
          can_review_expense_advances = false,
          can_review_attendance_corrections = false,
          can_review_overtime = false,
          deleted_at = clock_timestamp(), deleted_by = p_actor
      where p.id = p_employee_id;
    v_mode := 'anonymized';
  end;

  perform set_config('app.account_actor', coalesce(prior_actor, ''), true);
  perform set_config('app.account_event', coalesce(prior_event, ''), true);
  return jsonb_build_object('mode', v_mode);
end;
$$;
revoke all on function public.backend_delete_employee(uuid, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.backend_delete_employee(uuid, uuid) to service_role;

commit;
