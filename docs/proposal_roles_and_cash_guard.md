# Proposal (NOT applied): choose a role when creating an account, and block admin cash requests in the database

Status: **waiting for your approval.** Nothing below has been run. The Flutter side is
ready behind `Constants.accountRoleAndPhone` (currently `false`).

## Why a backend change is needed

| Need | What the live backend does today |
|---|---|
| Admin creates an **admin** account | `employee-accounts` (Edge Function) rejects any field not in its list, so sending `role` fails with `invalid_input`. The `auth.users` insert trigger `private.on_auth_user_created()` always inserts `role = 'employee'` (only the one-time bootstrap creates an admin). No RPC changes a role afterwards. |
| Admins can't send cash requests via the API | `public.request_expense_advance` calls `private.require_actor()` (any active user), so an admin calling the API directly can still insert a request. The app now hides the screens from admins, but that is not a security boundary. |

The role can only be trusted if the server sets it: `app_metadata` is writable only with the
service key (held by the Edge Function), and both the function and the trigger already verify
that the creator is an active admin (`backend_validate_employee` → `private.require_backend_admin`,
and the trigger calls `private.require_backend_admin(creator)` again).

## 1. Edge Function `employee-accounts` (deploy a new version)

In `employeeInput(body)`:

```diff
-  const allowed = ['action','request_id','full_name','username','email','password','employee_code','schedule_id'];
+  const allowed = ['action','request_id','full_name','username','email','password','employee_code','schedule_id','role'];
   if (Object.keys(body).some(key => !allowed.includes(key))) fail('Unexpected employee field');
-  for (const key of allowed.filter(k=>k!=='action')) {
+  for (const key of allowed.filter(k=>k!=='action' && k!=='role')) {
     if (typeof body[key]!=='string') fail('All employee fields and request_id are required');
   }
+  const role = body.role ?? 'employee';
+  if (role!=='employee' && role!=='admin') fail('Role must be employee or admin');
   const details = {
     full_name: body.full_name.trim(), username: body.username.trim().toLowerCase(),
     email: body.email.trim().toLowerCase(), employee_code: body.employee_code.trim().toUpperCase(),
-    schedule_id: body.schedule_id,
+    schedule_id: body.schedule_id, role,
   };
```

`details` already flows into `app_metadata.attendance_account` and into
`backend_validate_employee`, so nothing else in the function changes. Older app versions
that don't send `role` keep creating employees.

## 2. Database migration

```sql
-- normalize_employee: keep the role (employee by default), reject anything else.
create or replace function private.normalize_employee(p_details jsonb)
returns jsonb language plpgsql security definer set search_path to '' as $function$
declare
  details jsonb;
  assigned_schedule uuid;
begin
  if p_details is null or jsonb_typeof(p_details) <> 'object' then
    raise exception 'Employee details must be a JSON object' using errcode = '22023';
  end if;

  details := jsonb_build_object(
    'full_name', btrim(p_details ->> 'full_name'),
    'username', lower(btrim(p_details ->> 'username')),
    'employee_code', upper(btrim(p_details ->> 'employee_code')),
    'email', lower(btrim(p_details ->> 'email')),
    'schedule_id', p_details ->> 'schedule_id',
    'role', coalesce(p_details ->> 'role', 'employee')            -- NEW
  );

  if details ->> 'role' not in ('employee', 'admin') then          -- NEW
    raise exception 'Role must be employee or admin' using errcode = '22023';
  end if;

  -- (unchanged checks below)
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
```

In `private.on_auth_user_created()` change one line in the non-bootstrap branch
(the creator is already verified as an admin two lines above it):

```diff
-   assigned_role:='employee';
+   assigned_role:=d->>'role';   -- 'employee' unless an admin asked for 'admin'
```

In `public.backend_validate_employee` add the role to the replay comparison, so a retried
request id can't silently change the role:

```diff
        or existing_email is distinct from
-          (details ->> 'email') then
+          (details ->> 'email')
+       or existing_profile.role is distinct from
+          (details ->> 'role') then
```

Block admins from sending cash requests (`public.request_expense_advance`, after
`employee_uuid := private.require_actor();`):

```sql
  if (select role from public.profiles where id = employee_uuid) = 'admin' then
    raise exception 'Admins cannot submit expense requests' using errcode = '42501';
  end if;
```

## 3. After approval (app side, already prepared)

1. Set `Constants.accountRoleAndPhone = true` in `lib/core/constants/constants.dart`.
   The Add Employee form then shows an Employee / Admin selector (Employee by default) and
   sends `role` to `create_employee`.
2. Test: create one employee and one admin; sign in with each; confirm the admin sees the
   Admin dashboard (Profile → Admin dashboard) and the employee doesn't.
3. Test the guard: as an admin, `select public.request_expense_advance(10, 'x');` must fail
   with 42501.

## Rollback

Restore the previous function bodies (saved by `pg_get_functiondef` before applying) and
redeploy the previous Edge Function version. Existing accounts and roles are not touched by
any of these changes.
