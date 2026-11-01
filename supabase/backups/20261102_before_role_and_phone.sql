-- Rollback for 20261102090100_account_role_and_phone.sql.
-- The live definitions taken with pg_get_functiondef on 2026-11-02, just before
-- the migration was applied. Run this file, then (only if no phone is stored):
--   alter table public.profiles drop constraint if exists profiles_phone_format;
--   alter table public.profiles drop column if exists phone;
-- and redeploy employee-accounts version 1.

CREATE OR REPLACE FUNCTION public.backend_validate_employee(p_actor uuid, p_request_id uuid, p_details jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  details jsonb;
  existing_profile public.profiles%rowtype;
  existing_email text;
begin
  -- Verify the requesting Admin.
  perform private.require_backend_admin(p_actor);

  if p_request_id is null then
    raise exception 'A provisioning request ID is required'
      using errcode = '22023';
  end if;

  details := private.normalize_employee(p_details);

  -- Check whether this request already created an account.
  select *
  into existing_profile
  from public.profiles
  where provisioning_request_id = p_request_id;

  if found then
    select lower(email)
    into existing_email
    from auth.users
    where id = existing_profile.id;

    if existing_profile.created_by is distinct from p_actor
       or existing_profile.username is distinct from
          (details ->> 'username')
       or existing_profile.employee_code is distinct from
          (details ->> 'employee_code')
       or existing_profile.full_name is distinct from
          (details ->> 'full_name')
       or existing_profile.schedule_id is distinct from
          ((details ->> 'schedule_id')::uuid)
       or existing_email is distinct from
          (details ->> 'email') then
      raise exception
        'This request ID was already used for different account details'
        using errcode = '23505';
    end if;

    return jsonb_build_object(
      'details', details,
      'existing_id', existing_profile.id
    );
  end if;

  if exists (
    select 1
    from public.profiles
    where username = details ->> 'username'
       or employee_code = details ->> 'employee_code'
  ) or exists (
    select 1
    from auth.users
    where lower(email) = details ->> 'email'
  ) then
    raise exception
      'Username, employee code or email already exists'
      using errcode = '23505';
  end if;

  return jsonb_build_object(
    'details', details,
    'existing_id', null
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION private.normalize_employee(p_details jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  details jsonb;
  assigned_schedule uuid;
begin
  if p_details is null
     or jsonb_typeof(p_details) <> 'object' then
    raise exception 'Employee details must be a JSON object'
      using errcode = '22023';
  end if;

  details := jsonb_build_object(
    'full_name', btrim(p_details ->> 'full_name'),
    'username', lower(btrim(p_details ->> 'username')),
    'employee_code', upper(btrim(p_details ->> 'employee_code')),
    'email', lower(btrim(p_details ->> 'email')),
    'schedule_id', p_details ->> 'schedule_id'
  );

  if coalesce(length(details ->> 'full_name'), 0)
       not between 1 and 200 then
    raise exception 'Full name must contain 1–200 characters'
      using errcode = '22023';
  end if;

  if coalesce(details ->> 'username', '')
       !~ '^[a-z0-9][a-z0-9._-]{2,63}$' then
    raise exception 'Invalid username'
      using errcode = '22023';
  end if;

  if coalesce(details ->> 'employee_code', '')
       !~ '^[A-Z0-9][A-Z0-9_-]{1,49}$' then
    raise exception 'Invalid employee code'
      using errcode = '22023';
  end if;

  if coalesce(length(details ->> 'email'), 0)
       not between 3 and 254
     or coalesce(details ->> 'email', '')
       !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'Invalid email address'
      using errcode = '22023';
  end if;

  begin
    assigned_schedule :=
      (details ->> 'schedule_id')::uuid;
  exception
    when invalid_text_representation then
      raise exception 'Schedule ID must be a valid UUID'
        using errcode = '22023';
  end;

  perform 1
  from public.work_schedules
  where id = assigned_schedule
  for share;

  if not found then
    raise exception 'Assigned work schedule does not exist'
      using errcode = '22023';
  end if;

  return details;
end;
$function$
;

CREATE OR REPLACE FUNCTION private.on_auth_user_created()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
   -- Prevalidation ran in Edge. Do not query auth.users for duplicate email here:
   -- NEW is already visible inside this AFTER INSERT trigger. Native Auth owns email
   -- uniqueness; profile unique constraints resolve request/username/code races.
   assigned_role:='employee';
 end if;
 prior_actor:=current_setting('app.account_actor',true);
 prior_event:=current_setting('app.account_event',true);
 perform set_config('app.account_actor',coalesce(creator::text,''),true);
 perform set_config('app.account_event',case when is_bootstrap then 'bootstrap_admin' else 'admin_created_employee' end,true);
 insert into public.profiles(id,employee_code,username,full_name,role,is_active,must_change_password,schedule_id,created_by,provisioning_request_id)
 values(new.id,d->>'employee_code',d->>'username',d->>'full_name',assigned_role,true,true,
   (d->>'schedule_id')::uuid,creator,req);
 -- Guided setup audits profile INSERT explicitly; avoid doubling an existing generic INSERT audit.
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
end $function$
;
