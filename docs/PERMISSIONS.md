> **Superseded 2026-11-11 (later the same day):** the live database already has its own model (reviewer flags + assigned requests). The app now uses that; this 15-code design and its migration are NOT applied and NOT used. See DELEGATED_REVIEWS_AND_EMPLOYEE_EDIT.md.

# Permissions per person — proposal and implementation (2026-11-11)

**Status:** app code done and tested, switched **off**. The database change is a file only:
`supabase/migrations/20261111090000_permissions.sql`, **not applied** (see the incident below).
Rollback: `supabase/backups/20261111_before_permissions.sql`. Nothing changes for anyone until
the migration is applied and `Constants.dynamicPermissions` is set to `true`.

## Incident 2026-11-11 (applied, then rolled back)

| UTC | What |
|---|---|
| 22:18:46 | Migration applied with the owner's approval (after a read-only baseline of what each account can see) |
| 22:19:30 | Verification as the real users failed at once: `permission denied for function has_any_permission`. The migration revoked EXECUTE from `PUBLIC`, which also took it from `authenticated`; the new read policies run those checks as the signed-in user, so **every signed-in read would have failed** |
| 22:20 | The 2-line fix (GRANT EXECUTE to `authenticated`) was blocked by the session's safety check; the owner chose to roll back |
| 22:21:31 | First rollback attempt refused atomically (drop order: a policy on `user_permissions` depends on `has_permission`); nothing changed |
| 22:22:12 | Rollback applied (order fixed in the backup file) |

- **Impact:** the API and storage logs show **0 requests** from the app during those 3½ minutes,
  so no user was affected.
- **After rollback:** each account's visibility is identical to the baseline (admins 8 profiles /
  7 days / 13 events / 1 correction / 6 cash / 57 audit / 13 photos; employees only their own);
  no permission objects remain; the 5 functions and 8 policies are the originals.
- **Fixed in the files:** the GRANT is now in the migration (section 3); the rollback drops tables
  before functions.
- **Process change for the next attempt:** first a dry run — the whole migration **plus** the
  verification inside one transaction that always rolls back (Postgres DDL is transactional), so
  a mistake like this costs nothing. Only then apply for real and verify again.

## What you get

On an employee's page (admin area): **Permissions** → switches grouped by Attendance, Cash
requests, Employees, Reports → **Review and save** shows what will be granted/removed → saved
in one step and recorded in the audit history.

Examples from your brief:

| Person | Grant | Result |
|---|---|---|
| Employee A | Correct attendance times (+ see everyone's attendance) | Edit times on any closed day of others |
| Employee B | See everyone's cash requests | Opens the admin area with only "Cash requests", read-only |
| Employee C | + Approve / Reject cash requests | Approve and reject buttons appear |
| Employee D | See / approve / reject correction requests | Corrections review |
| Employee E | See HR report figures + Export the HR workbook | HR reports + Excel |

## Catalog (15 codes)

| Code | Means | Database checks it in |
|---|---|---|
| `attendance.view_all` | everyone's days, locations, photos | RLS on attendance, events, selfie bucket |
| `attendance.view_correction_requests` | everyone's correction requests | RLS on corrections (+ the related days) |
| `attendance.approve_correction` / `reject_correction` | decide corrections | `review_request` |
| `attendance.edit` | correct closed days | `admin_correct_attendance` |
| `attendance.edit_schedule` | schedules, grace period | `admin_assign_schedule`, `admin_set_grace` |
| `cash.view_all` | everyone's cash requests | RLS on cash requests |
| `cash.approve` / `cash.reject` | decide cash requests | `review_request` |
| `employees.view` | employee list and profiles | RLS on profiles |
| `employees.edit` | activate / deactivate | `admin_set_employee_active` |
| `employees.manage_permissions` *(sensitive)* | this screen | the new functions |
| `reports.view` / `reports.export` | HR reports / Excel | RLS (reads all attendance) / app |
| `audit.view` *(sensitive)* | audit history | RLS on audit_logs |

Not codes (unchanged): everyday self-service for every active account (own attendance,
check-in/out, own corrections, own cash requests), and **account creation / password-reset
emails**, which stay with the admin role (they run through the `employee-accounts` Edge Function;
moving them is a separate change). Payroll codes are left out: there is no payroll feature.

## Rules (enforced in the database, mirrored by the app)

1. **Default deny.** Effective = role default OR individual grant. Role `admin` holds every code;
   role `employee` none. So on day one nobody gains or loses anything.
2. Only someone with `employees.manage_permissions` can grant or remove.
3. **Never yourself** (also a table constraint: `granted_by <> user_id`).
4. **Only employee accounts** get individual grants (admins already have everything; this also
   prevents admins locking each other out).
5. **No escalation:** you can only grant or remove codes you hold yourself.
6. **Sensitive codes** (`employees.manage_permissions`, `audit.view`) only by a role admin, so a
   delegated manager can't create more managers.
7. **Revocation is immediate:** every request re-reads the tables; nothing is cached in tokens.
   The app refreshes its view on resume and after saving.
8. **Audited:** `user_permissions` uses the existing `audit_change` trigger (actor, old/new row).
9. Self-review stays impossible for cash and corrections (unchanged checks + constraints).

## What the migration changes

- New: tables `permissions`, `role_permissions`, `user_permissions` (RLS on, read-only to clients);
  functions `private.has_permission`, `private.has_any_permission`, `private.require_permission`,
  `public.get_my_permissions`, `public.admin_get_user_permissions`,
  `public.admin_set_user_permissions` (`anon` revoked).
- Changed: 8 read policies (`is_admin()` → the codes above) and 5 functions — only their
  authorization line (`require_actor(true)` → `require_permission(code)`); `review_request` checks
  the code per decision (approve vs reject) and keeps overtime admin-only.
- Not changed: data, Edge Functions, auth hook, account creation, storage upload rules.

## Before / after for today's 8 accounts (3 admins, 5 employees)

Identical, because admins get every code from their role and employees have no grants until an
admin gives one.

## Applying (needs your explicit approval)

1. Apply the migration (one transaction).
2. Verify as the real users inside a block that always rolls back: admin still reads everything
   and can review; an employee still reads only their own rows; grant `cash.view_all` to an
   employee → they read all cash requests but cannot approve; grant `cash.approve` → can approve
   others' but not their own; a delegate cannot grant `audit.view` or anything they lack; nobody
   can change their own permissions; revoking removes access in the same transaction.
3. Check Supabase advisors.
4. Set `Constants.dynamicPermissions = true`, run tests, build the APK.

## Tests

`test/permissions_test.dart` (13): role fallback, route guard per screen, cubit (off / on /
refresh / failure never keeps another account's set), repository calls and error mapping, edit /
diff / save / refused save, a cash-only delegate's dashboard, the management screen with locked
sensitive codes and the confirmation. Full suite: 354 passing.
