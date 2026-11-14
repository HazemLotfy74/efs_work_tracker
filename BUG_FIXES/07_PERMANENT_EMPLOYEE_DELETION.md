# 07 — Permanent employee account deletion (2026-11-13)

**Status: implemented and tested locally; NOT deployed, NOT verified on the real backend.**
The Supabase connector was not attached to this session, so the migration could not be applied or
checked against the live schema, and the Edge Function could not be deployed. Until both are done,
the new **Delete employee account** button answers "service unavailable" and deletes nothing.
**No real Auth account has been deleted by this work.**

## How it works
Admin → employee → **Delete employee account / حذف حساب الموظف** → warning dialog → server.

1. **App** sends only the employee's id to the `employee-accounts` Edge Function, with the admin's own token. It holds no privileged key.
2. **Edge Function** (`delete_employee`): verifies the token with Supabase Auth, refuses a caller deleting themselves, then calls the database.
3. **Database** (`backend_delete_employee`, callable by the server only), in one transaction:
   - checks the caller is an active admin with a completed password change (`require_backend_admin`);
   - refuses unless the target is an **employee** account — admin accounts are never deletable from the app, which is what protects the last administrator and any system account;
   - removes the access and personal records listed below;
   - tries to delete the profile. If nothing refers to it, it is gone (**hard**). If history refers to it, the database's foreign keys refuse, and the profile is locked instead (**anonymized**).
4. **Edge Function** then removes the login in Supabase Auth with the service key: a real delete for *hard*, a **soft delete** for *anonymized*.

### Why two outcomes
Every foreign key to `profiles` is `ON DELETE RESTRICT`, `profiles.id` itself references `auth.users`
with `RESTRICT`, and attendance evidence and the audit log are append-only. So an employee who has
ever checked in cannot be removed as a row without destroying payroll and audit history. For them
the account is destroyed and the history is kept. Supabase's soft delete keeps the `auth.users` row
only as an anchor: the email and phone are replaced by a hash, the password is erased, tokens and
metadata are cleared and all sessions are ended. It is not reversible. (Checked against the Supabase
Auth source on 2026-11-13.)

This is not deactivation: a deactivated account can be switched back on with its email and password
intact; a deleted one has no login left and its record can never be changed again.

## What happens to each kind of data
| Data | Result |
|---|---|
| Login (email, password) in Supabase Auth | **Destroyed** (hard delete, or soft delete when history exists) |
| Sessions and refresh tokens | **Deleted** — signed out everywhere at once |
| Registered phones (push tokens) and queued pushes | **Deleted** |
| The employee's notifications | **Deleted** |
| Pending login-email change | **Deleted** |
| Reviewer permissions | **Removed** |
| Phone number | **Removed** |
| Requests assigned to the employee for review | Returned to the admins, still pending |
| The employee's own pending cash / overtime / correction requests | Closed as rejected by the deleting admin, note "Employee account deleted" |
| Profile row | **Deleted** when nothing refers to it; otherwise **kept, locked**, with full name, username and employee code only |
| Attendance days and their check-in/out evidence (incl. selfies) | **Kept** — payroll and attendance history; append-only by design |
| Cash, overtime and correction requests with their decisions | **Kept** — accounting history |
| Decisions the employee made as a reviewer | **Kept** — who decided what |
| Audit log | **Kept** — append-only; it also contains earlier copies of the profile |

Consequences of keeping the name, username and employee code on a locked record: past reports still
show whose days they were, and that username and employee code cannot be reused for a new hire.
The original login email can be reused.

## Security
| Layer | Protection |
|---|---|
| App | Button shown only to the admin role, only on employee accounts, never on your own profile. The employee page is behind the router's admin guard |
| App | Warning dialog naming the employee; the delete button stays disabled until "I understand this is permanent" is ticked; tapping outside cancels; buttons locked and a progress bar shown while it runs; the page closes only after the server confirms |
| Edge Function | Caller taken from the token verified by Supabase Auth, never from the request; unknown fields refused; id must be a UUID; self-deletion refused; no database detail or key in any answer |
| Database | `backend_delete_employee` executable by `service_role` only; checks the admin itself; refuses self and any non-employee target; a refused call changes nothing; everything in one transaction |
| Database | A deleted profile is immutable (trigger): cannot be re-activated, edited, promoted or given permissions |
| Already in place | Clients have no write access to any table; a deleted account's session is gone, so every request it sends is refused by the single-session rule and `is_active` |

## Files
| File | Change |
|---|---|
| `supabase/migrations/20261113110000_delete_employee.sql` | **Not applied.** Columns `profiles.deleted_at`, `deleted_by`; trigger `protect_deleted_profile`; function `backend_delete_employee` |
| `supabase/backups/20261113_delete_employee_rollback.sql` | Rollback (cannot restore accounts already deleted) |
| `supabase/functions/employee-accounts/index.ts` | **Not deployed.** Action `delete_employee`; transport `deleteUser` |
| `admin/domain/repositories/admin_repository.dart`, `admin/data/repositories/supabase_admin_repository.dart` | `deleteEmployee`; deleted accounts left out of employee lists and pages; works with a database that has no `deleted_at` yet |
| `admin/presentation/manager/employee_details_cubit/employee_details_cubit.dart` | `delete()` |
| `admin/presentation/views/employee_details_view.dart` | Button, warning dialog, progress bar |
| `admin/presentation/widgets/admin_dashboard_view_body.dart` | Reloads the list when the employee page reports a deletion |
| `attendance_session/presentation/widgets/prepare/info_row.dart` | Fixed an overflow on narrow Arabic screens found by the new test |
| `lib/l10n/app_ar.arb`, `app_en.arb` | 7 strings (the Arabic wording asked for) |
| Tests | `supabase/tests/delete_employee.test.mjs`, `supabase/tests/employee_accounts_delete.test.mjs`, `test/delete_employee_test.dart`, fake updated |

## Test results (all executed here)
| Command | Result |
|---|---|
| `node --test supabase/tests/*.mjs` | **24 passed, 0 failed** (16 new) |
| `flutter test` | **460 passed, 0 failed** (17 new) |
| `flutter analyze` | 0 errors, 0 warnings |
| `flutter build apk --release --split-per-abi` | Built |

| # | Scenario | Result | How |
|---|---|---|---|
| 1 | Admin sees the Delete button | passed | widget test |
| 2 | Warning dialog appears, with the name | passed | widget test (English and Arabic, 320 px, large text) |
| 3 | Cancel deletes nothing | passed | widget test |
| 4 | Confirm runs the backend operation | passed | widget test → fake; function test → recorded calls; SQL test |
| 5 | Employee disappears afterwards | passed | page closes with "reload"; deleted rows filtered from lists |
| 6 | Auth account actually removed | **not verified** | the function calls `DELETE /auth/v1/admin/users/{id}` with the right flag (tested against a recorder); never run against Supabase Auth |
| 7 | Personal records and device tokens | passed | SQL test on in-memory Postgres |
| 8 | History consistent, nothing orphaned | passed | SQL test |
| 9 | Regular employee cannot see the button | passed | widget test, with and without reviewer permissions |
| 10 | Regular employee cannot delete via the API | passed (simulated) | SQL: employee as caller refused, `anon`/`authenticated` cannot execute; function: refusal → 403, Auth untouched |
| 11 | Nobody deletes their own account | passed (simulated) | app, function and SQL each refuse |
| 12 | Last admin cannot be deleted | passed (simulated) | no admin account can be deleted at all |
| 13 | Deleted employee's session stops working | **partly** | SQL: sessions deleted, profile inactive. Not run with a real signed-in phone |
| 14 | A failure leaves nothing half-done | passed | SQL: forced mid-way error → state identical. Function: Auth failure after the database step is reported and a retry finishes it |

A real defect was found and fixed by the SQL test: on Postgres 17 (production's version) a blocked
delete raises `restrict_violation`, not `foreign_key_violation`; the function now handles both.

**Not tested with multiple real accounts**: there are no test accounts, production is the only
backend, and there was no database access. The SQL tests use a small copy of the schema built from
the repo's notes, not the live schema.

## To deploy (needs you)
1. Re-attach the Supabase connector, or use the dashboard.
2. Before applying, check three assumptions against the live database: `private.require_backend_admin(uuid)` exists; `private.employee_email_changes.employee_id` exists; no existing trigger on `profiles` refuses the update or delete this function performs.
3. Run `supabase/migrations/20261113110000_delete_employee.sql`.
4. Confirm the deployed `employee-accounts` matches the repo's previous version, then deploy the new one: `supabase functions deploy employee-accounts --no-verify-jwt`.
5. Create a throwaway employee and delete it from the app (expect *hard*). Then, with your explicit approval only, delete one real former employee and check: they cannot sign in, they are gone from the list, their past days still show in reports.

## Limits
- A half-finished deletion is possible if Supabase Auth is unreachable right after the database step: the account already cannot be used, and pressing Delete again completes it.
- The audit log still holds earlier copies of the profile (including a phone number if one was ever stored). It is append-only; erasing from it would need a deliberate, separate decision.
- Selfies in Storage are kept as attendance evidence.
