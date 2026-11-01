-- Role choice and an optional phone number for admin-created accounts.
-- Backward-compatible: one new nullable column; existing rows, roles and the
-- accounts created so far are untouched. Deploy together with the new
-- supabase/functions/employee-accounts/index.ts (it forwards role and phone).
--
-- Trust model (unchanged): the role and phone travel only inside
-- app_metadata.attendance_account, which only the Edge Function (service
-- key) can write. Both the Edge Function (backend_validate_employee) and the
-- auth.users trigger re-check that the creator is an active admin, so an
-- employee can never create an admin or raise their own role.

-- 1. Optional phone, same format as the existing private.normalize_phone.
alter table public.profiles
  add column if not exists phone text;

alter table public.profiles
  drop constraint if exists profiles_phone_format;
alter table public.profiles
  add constraint profiles_phone_format
  check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$');

-- 2. Normalize role (default employee) and phone (null when empty).
create or replace function private.normalize_employee(p_details jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  details jsonb;
  assigned_schedule uuid;
  phone_text text;
begin
  if p_details is null or jsonb_typeof(p_details) <> 'object' then
    raise exception 'Employee details must be a JSON object' using errcode = '22023';
  end if;

  phone_text := nullif(btrim(coalesce(p_details ->> 'phone', '')), '');            -- NEW

  details := jsonb_build_object(
    'full_name', btrim(p_details ->> 'full_name'),
    'username', lower(btrim(p_details ->> 'username')),
    'employee_code', upper(btrim(p_details ->> 'employee_code')),
    'email', lower(btrim(p_details ->> 'email')),
    'schedule_id', p_details ->> 'schedule_id',
    'role', coalesce(nullif(btrim(p_details ->> 'role'), ''), 'employee'),           -- NEW
    'phone', case when phone_text is null then null                                  -- NEW
                  else private.normalize_phone(phone_text) end
  );

  if details ->> 'role' not in ('employee', 'admin') then                             -- NEW
    raise exception 'Role must be employee or admin' using errcode = '22023';
  end if;

  if coalesce(length(details ->> 'full_name'), 0) not between 1 and 200 then
    raise exception 'Full name must contain 1–200 characters' using errcode = '22023';
  end if;
  if coalesce(details ->> 'username', '') !~ '^[a-z0-9][a-z0-9._-]{2,63}$' then
    raise exception 'Invalid username' using errcode = '22023';
  end if;
  if coalesce(details ->> 'employee_code', '') !~ '^[A-Z0-9][A-Z0-9_-]{1,49}$' then
    raise exception 'Invalid employee code' using errcode = '22023';
  end if;
  if coalesce(length(details ->> 'email'), 0) not between 3 and 254
     or coalesce(details ->> 'email', '') !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'Invalid email address' using errcode = '22023';
  end if;

  begin
    assigned_schedule := (details ->> 'schedule_id')::uuid;
  exception when invalid_text_representation then
    raise exception 'Schedule ID must be a valid UUID' using errcode = '22023';
  end;

  perform 1 from public.work_schedules where id = assigned_schedule for share;
  if not found then
    raise exception 'Assigned work schedule does not exist' using errcode = '22023';
  end if;

  return details;
end;
$function$;

-- 3. A retried request id may not change the role or phone.
create or replace function public.backend_validate_employee(
  p_actor uuid,
  p_request_id uuid,
  p_details jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  details jsonb;
  existing_profile public.profiles%rowtype;
  existing_email text;
begin
  perform private.require_backend_admin(p_actor);

  if p_request_id is null then
    raise exception 'A provisioning request ID is required' using errcode = '22023';
  end if;

  details := private.normalize_employee(p_details);

  select * into existing_profile
  from public.profiles
  where provisioning_request_id = p_request_id;

  if found then
    select lower(email) into existing_email from auth.users where id = existing_profile.id;

    if existing_profile.created_by is distinct from p_actor
       or existing_profile.username is distinct from (details ->> 'username')
       or existing_profile.employee_code is distinct from (details ->> 'employee_code')
       or existing_profile.full_name is distinct from (details ->> 'full_name')
       or existing_profile.schedule_id is distinct from ((details ->> 'schedule_id')::uuid)
       or existing_email is distinct from (details ->> 'email')
       or existing_profile.role is distinct from (details ->> 'role')                  -- NEW
       or existing_profile.phone is distinct from (details ->> 'phone') then            -- NEW
      raise exception 'This request ID was already used for different account details'
        using errcode = '23505';
    end if;

    return jsonb_build_object('details', details, 'existing_id', existing_profile.id);
  end if;

  if exists (
    select 1 from public.profiles
    where username = details ->> 'username'
       or employee_code = details ->> 'employee_code'
  ) or exists (
    select 1 from auth.users where lower(email) = details ->> 'email'
  ) then
    raise exception 'Username, employee code or email already exists' using errcode = '23505';
  end if;

  return jsonb_build_object('details', details, 'existing_id', null);
end;
$function$;

-- 4. The profile gets the chosen role and phone (only from an admin creator).
create or replace function private.on_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare m jsonb; d jsonb; creator uuid; req uuid; is_bootstrap boolean;
 prior_actor text; prior_event text; assigned_role text;
begin
 select u.raw_app_meta_data->'attendance_account' into m from auth.users u where u.id=new.id; -- user_metadata is NEVER trusted here
 if m is null then raise exception 'Accounts must be created through the authorized Admin backend'; end if;
 req:=(m->>'request_id')::uuid;
 if req is null then raise exception 'Provisioning request ID required'; end if;
 d:=private.normalize_employee(m);
 if lower(new.email) is distinct from d->>'email' then raise exception 'Provisioning email mismatch'; end if;
 is_bootstrap:=coalesce(m->'bootstrap'='true'::jsonb,false);
 if is_bootstrap then
   perform pg_advisory_xact_lock(hashtextextended('attendance:first-admin',0));
   if exists(select 1 from public.profiles where role='admin') then
     raise exception 'An admin already exists; bootstrap is closed' using errcode='42501';
   end if;
   creator:=null; assigned_role:='admin';
 else
   creator:=(m->>'created_by')::uuid;
   perform private.require_backend_admin(creator);
   assigned_role:=d->>'role';                                                          -- CHANGED (was 'employee')
 end if;
 prior_actor:=current_setting('app.account_actor',true);
 prior_event:=current_setting('app.account_event',true);
 perform set_config('app.account_actor',coalesce(creator::text,''),true);
 perform set_config('app.account_event',case when is_bootstrap then 'bootstrap_admin' else 'admin_created_employee' end,true);
 insert into public.profiles(id,employee_code,username,full_name,role,is_active,must_change_password,schedule_id,created_by,provisioning_request_id,phone) -- CHANGED (+phone)
 values(new.id,d->>'employee_code',d->>'username',d->>'full_name',assigned_role,true,true,
   (d->>'schedule_id')::uuid,creator,req,d->>'phone');                                 -- CHANGED (+phone)
 if not exists (select 1 from pg_catalog.pg_trigger
   where tgrelid='public.profiles'::regclass and not tgisinternal
     and tgfoid='private.audit_change()'::regprocedure
     and (tgtype::integer & 4)=4 and tgenabled in ('O','A')) then
   insert into public.audit_logs(actor_id,actor_kind,action,table_name,row_key,new_data)
   values(creator,case when creator is null then 'database' else 'user' end,
     'INSERT','profiles',jsonb_build_object('id',new.id,'event',
       case when is_bootstrap then 'bootstrap_admin' else 'admin_created_employee' end),
     (select to_jsonb(p) from public.profiles p where p.id=new.id));
 end if;
 perform set_config('app.account_actor',coalesce(prior_actor,''),true);
 perform set_config('app.account_event',coalesce(prior_event,''),true);
 return new;
end $function$;

-- Rollback: restore the three function bodies saved with pg_get_functiondef
-- before running this file, then (only if no phone is stored yet):
--   alter table public.profiles drop constraint if exists profiles_phone_format;
--   alter table public.profiles drop column if exists phone;
