-- Undoes migrations/20261113110000_delete_employee.sql.
-- Accounts already deleted stay deleted: their Auth logins are gone and cannot
-- be restored. Dropping the columns only removes the "deleted" marker, so run
-- this only if no account was deleted, or after noting which ones were:
--   select id, full_name, employee_code, deleted_at from public.profiles where deleted_at is not null;
begin;
drop function if exists public.backend_delete_employee(uuid, uuid);
drop trigger if exists protect_deleted_profile on public.profiles;
drop function if exists private.protect_deleted_profile();
drop index if exists public.profiles_deleted_by_idx;
alter table public.profiles drop column if exists deleted_by, drop column if exists deleted_at;
commit;
