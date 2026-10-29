# Full App Audit and Plan (Phase A)

Date: 2026-10-29. Read-only. The live Supabase project (`fotxyzooanysjthovpfz`) was
inspected with `SELECT` queries only. No DDL, policy, function, grant, data or
Auth-setting change was made. Earlier reports still apply and are not repeated
here: `supabase_auth_audit.md`, `attendance_checkin_checkout.md`,
`attendance_duration_and_pages.md`.

## 1. Architecture (as built)

| Layer | What the project uses |
|---|---|
| Entry | `lib/main.dart`: `Supabase.initialize` → `setup()` (GetIt) → `AuthCubit`, `AttendanceSessionCubit`, `GoRouter` created once |
| DI | `lib/core/services/getit_services.dart` (singletons), exposed to widgets by `MultiRepositoryProvider` in `main.dart` |
| State | `flutter_bloc` Cubits with sealed states, one folder per cubit under `presentation/manager/` |
| Data | `domain/repositories` interfaces → `data/repositories/supabase_*` behind `DatabaseServices` (`getData` reads, `rpc` writes) |
| Errors | Per-feature enums implementing `Exception` (`AttendanceFailure`, `RequestFailure`, `CorrectionFailure`), `AuthFailure`; each has an l10n text extension |
| Routing | `go_router` with an auth `redirect` (`AppRouter._redirect`) and a `StatefulShellRoute` for the 4 tabs |
| l10n | gen-l10n, `lib/l10n/app_{en,ar}.arb`; locale is **hard-coded to `ar`** in `main.dart` |
| Time | `ClockCubit` (minute ticks); business date and shift instants in the schedule's IANA timezone (`timezone` package) |

## 2. Database (live, verified)

- **One company.** No company/tenant table or column exists. Every admin sees every
  employee. No tenancy layer is introduced.
- **Tables (all RLS on, `authenticated` has SELECT only):** `profiles`, `work_schedules`,
  `schedule_days`, `attendance_records`, `attendance_events`, `overtime_requests`,
  `expense_advance_requests`, `attendance_correction_requests`, `audit_logs`.
- **Read policies:** own rows, or all rows for an active admin (`private.is_admin()`);
  `audit_logs` admin only; schedules readable by any active user.
- **Writes only through `SECURITY DEFINER` functions** that call
  `private.require_actor([admin])` and take the user from `auth.uid()`:
  `check_in`, `check_out`, `request_overtime`, `request_expense_advance`,
  `request_attendance_correction`, `review_request(kind, id, approve, note)` (kinds
  `overtime`, `expense_advance`, `correction`; blocks self-review and second reviews),
  `admin_set_grace`, `admin_assign_schedule`, `admin_set_employee_active`,
  `get_account_status`.
- **Server time:** `check_in` / `check_out` stamp `clock_timestamp()` themselves; the
  client sends only location and selfie path. Device clock changes cannot move
  official times. ✔
- **Auto-close:** cron `* * * * *` → `private.auto_close_attendance()`; a day closed this
  way keeps `actual_checkout = NULL`, `auto_closed = true`. The app shows it as
  "Needs review" with no hours (no false overtime). ✔
- **Corrections:** `effective_checkin/checkout` + `has_correction` are set only by an
  approved correction; actual times and evidence are never overwritten. ✔
- **Triggers:** `audit_change` on every business table, append-only `audit_logs` and
  `attendance_events`, `touch_updated_at`, timezone validation.
- **Storage:** private bucket `attendance-evidence` (5 MB, jpeg/png/webp), path
  `<uid>/<uuid>.<ext>`.
- **Edge Function `employee-accounts`** (verifies the caller's token against Auth):
  `create_employee` (admin; idempotent by client `request_id`; uses the service key
  server-side, so the admin's session is untouched), `change_password` (clears
  `must_change_password`), `send_password_reset` (admin; server-configured redirect).

## 3. Feature status

| Feature | Status before this work |
|---|---|
| Login / logout / session restore / role routing | Done (`AuthCubit`, router redirect) |
| Change password (first login) | Done via Edge Function |
| **Forgot password** | **Broken** — see §4 B-1 |
| Check-in / check-out (selfie + GPS, retries, reconcile) | Done, server-timed, idempotent by selfie path |
| Durations, 8 h threshold, observed overtime | Done (`WorkDuration`), verified hours only |
| History / day details | Done |
| Correction request + admin review | In progress in this session |
| Overtime requests / cash (expense advance) requests, employee side | In progress in the sibling session (`overtime-cash-wiring.md`) |
| **Admin dashboard / live attendance** | **Missing** |
| **Employee directory / employee details** | **Missing** |
| **Add employee account** | **Missing** (backend exists) |
| **Admin review of cash / overtime requests** | **Missing** (backend exists: `review_request`) |
| **Language switching** | **Missing** (locale hard-coded) |
| Notifications tab, settings, privacy | Placeholders; no backing tables for notifications |

## 4. Bugs and security findings

| ID | Severity | Finding |
|---|---|---|
| B-1 | High | Forgot password cannot complete: `resetPasswordForEmail` is called without `redirectTo` (the link opens the dashboard Site URL, not the app); Android has no intent-filter and iOS no URL scheme for a callback; `AuthCubit` reacts only to sign-out, so a recovery session from a deep link never reaches the change-password screen. |
| B-2 | Medium (tests) | `ClockCubit(now: fixed UTC time)` builds the next minute from the UTC fields as *local* time. On a machine east of UTC the delay is negative, so the timer re-fires immediately forever. Only affects tests with a fixed UTC clock; real use passes local `DateTime.now()`. |
| S-1 | Medium (latent, DB) | Storage policies `attendance_selfie_no_delete/no_update` are permissive with `bucket_id <> 'attendance-evidence'`: they *grant* delete/update on any other bucket. Harmless today (one bucket). Proposal only: make them `AS RESTRICTIVE` or drop them. **Not changed.** |
| S-2 | Info | The UI hides admin screens; authorization is enforced by RLS and `require_actor(true)`. Verified for every admin RPC. |
| S-3 | Unverified | Whether the Custom Access Token Hook is enabled and sign-ups are disabled (dashboard only). |

## 5. Limitations of the existing schema (no change made)

- No company/tenant model: admins manage all employees.
- No breaks: the 8 h threshold applies to the recorded interval.
- No phone, avatar, job title or department columns.
- No notifications table.
- Employee profile fields can't be edited by the employee (no RPC); only the password.
- Creating an admin account is not possible from the app (`on_auth_user_created`
  always assigns `employee`).
- Schedules can be assigned and grace minutes changed (`admin_assign_schedule`,
  `admin_set_grace`), but shift hours/days can't be edited (no RPC).

## 6. Plan (this session)

1. Finish the correction workflow and its tests (fix B-2 in the tests).
2. Fix B-1: app deep link `efsworktracker://reset-password`, pass it as `redirectTo`,
   platform intent-filter/URL scheme, recovery event → change-password screen.
   Manual step: add the URL to Auth → URL Configuration → Redirect URLs (and the Edge
   secret `PASSWORD_RESET_REDIRECT_URL` for admin-sent resets).
3. Admin area (admins only, read via RLS, writes via existing RPCs/Edge Function):
   today's attendance board, employee directory + employee history, add employee,
   cash and overtime request review.
4. Language switch on the profile, persisted locally.
5. `dart format` (changed files), `flutter analyze`, `flutter test`; final report.

Test plan: fakes for `DatabaseServices` and repositories that mimic the live
function rules (never production data); widget tests for each new screen; no test
touches the real project.

---

## 7. What was implemented (Phases B–F)

No database object, policy, grant, function, setting or row was changed. Every
Supabase call in this work was a read-only `SELECT` against catalogs/tables or a
read of the Edge Function source.

| Area | Change | Main files |
|---|---|---|
| Corrections (employee) | "Request correction" on a day that needs review → form (check-in/out in company time, reason) → `request_attendance_correction`. Status of the latest request (pending / approved / rejected + reviewer note) on the day's page, read with `employee_id` filter. Client checks mirror the live function (work date, before shift end, check-out ≥ check-in and before midnight, reason 1–2000). | `lib/app/features/attendance_correction/` |
| Corrections (admin) | Pending queue (own requests hidden), approve / reject with optional note → `review_request('correction', …)`. | same |
| Forgot password (B-1) | `redirectTo: efsworktracker://reset-password`; Android intent-filter and iOS `CFBundleURLTypes` for that URL; Flutter's own deep-link routing turned off so only `supabase_flutter` handles it; new `AuthRepository.passwordRecovery` stream → `AuthCubit` sends the user to the existing change-password screen (Edge Function `change_password`, which clears `must_change_password`). | `supabase_auth_service.dart`, `auth_cubit.dart`, `AndroidManifest.xml`, `Info.plist`, `constants.dart` |
| Admin dashboard | Counts (checked in now, checked out, needs review, not checked in), search, every employee with today's status; a session still open after its shift end is flagged separately from "in progress". Pull to refresh, stale banner on a failed refresh; no polling, no Realtime. | `lib/app/features/admin/` |
| Employee history | Admin view of one employee's days (status, times, verified hours). | same |
| Add employee | Form → Edge Function `create_employee` with the admin's own token (the session is not replaced). Validation mirrors the function. A retry of the same details reuses the same `request_id`, so a lost answer never creates two accounts. | same + `core/services/accounts_function.dart` |
| Cash / overtime review | Pending requests of other employees, approve / reject with note → `review_request('expense_advance' | 'overtime', …)`. | same |
| Language | Arabic / English switch on the profile, applied immediately, stored in app preferences (`shared_preferences`, already in the app via `supabase_flutter`); does not touch the session or data. | `core/manager/locale_cubit.dart`, `main.dart`, `profile_view_body.dart` |
| Robustness | `ClockCubit` next-minute delay no longer negative for UTC clocks (B-2). Status badge text wraps instead of overflowing. | `clock_cubit.dart`, `custom_status_container.dart` |

Routes added (all `/admin*` redirect non-admins home; the database still enforces
the role): `/attendance/:id/correction`, `/admin`, `/admin/corrections`,
`/admin/requests`, `/admin/employees/new`, `/admin/employees/:id`.

## 8. Manual configuration still required (could not be verified from here)

1. Supabase Dashboard → Auth → URL Configuration → **Redirect URLs**: add
   `efsworktracker://reset-password`. Without it Supabase falls back to the Site URL
   and the link will not open the app.
2. Edge Function secret `PASSWORD_RESET_REDIRECT_URL` = `efsworktracker://reset-password`
   if admin-sent resets should open the app too.
3. Confirm the Custom Access Token Hook is enabled and public sign-ups are disabled.
4. Email delivery (SMTP) for reset emails was not tested.
5. The reset link must be opened on the phone that requested it (PKCE flow).

## 9. Remaining limitations

- Not built: notifications (no table), schedule hour editing (no RPC), employee
  self-edit of profile fields (no RPC), deactivate/reassign-schedule UI (RPCs exist:
  `admin_set_employee_active`, `admin_assign_schedule`, `admin_set_grace` — a good next step).
- `form_validator_functions.dart` returns English-only messages (pre-existing).
- Storage policy S-1 is a latent risk; fix proposal in §4, not applied.
- No device, Android build or iOS build was run in this session.

## 10. Test results (2026-10-29, this checkout)

| Check | Result |
|---|---|
| `flutter analyze` | PASS for this work — 4 issues, all pre-existing: 3 deprecation infos in generated `lib/generated/assets.dart`, 1 unused import in `overtime/.../inactive_overtime_filter.dart` |
| `flutter test` (whole suite, 251 tests) | PASS |
| `test/attendance_correction_test.dart` (45) | PASS — fake server applies the live `request_attendance_correction` / `review_request` rules; employee → admin approval → day verified, rejection → resubmit, one pending per day, own-request block, employee can't review |
| `test/admin_test.dart` (27) | PASS — work date in Cairo, RLS-style reads, request embeds, `review_request` params, `create_employee` params and idempotent retry, dashboard/add-employee/requests/profile-language widgets |
| `test/auth_test.dart` | PASS — includes reset link → change-password state |
| `dart format` | Run on changed files only |
| Android / iOS build, device run | NOT RUN |
| Password-reset email end to end | BLOCKED — needs the dashboard redirect URL (§8) and a real inbox/device |
| Live admin/employee sessions against Supabase | NOT RUN — tests use fakes only, never production data |

Release readiness: suitable for **internal testing** once §8 items 1–2 are set and an
Android debug build is checked on a device. Not production-ready until the reset flow
and account creation are verified on real devices.

## 11. Overtime requests removed (2026-10-29)

Requested by the user: overtime is automatic, so the overtime-request screens were removed.

- Removed: the overtime list, request form, submitted and details screens, their
  routes (`/overtime…`), the home "Need to work later?" entry, `OvertimeRepository`
  and its DI/provider, and the admin review of overtime requests (the admin queue is
  now cash requests only). The removed code was moved to the session scratchpad
  (`removed-overtime-requests/`), not just deleted; committed parts are also in git history.
- Overtime is now shown everywhere as the worked time beyond 8 hours
  (`WorkDuration.overtime`): the home/day summary tile "Overtime", the day details note,
  the check-out review. Nothing reads `overtime_requests` any more.
- Cash requests kept their filter chips, status badge and reason validator, moved to
  `lib/core/widgets/requests/` and `lib/core/functions/request_validators.dart`.
- Database: unchanged. The `overtime_requests` table and `request_overtime` function
  still exist; rows already in it are no longer shown.
- Tests after the change: `flutter analyze` 3 pre-existing infos (generated assets);
  `flutter test` 234 passed.
