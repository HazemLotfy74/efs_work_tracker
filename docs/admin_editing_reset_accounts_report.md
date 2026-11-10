# Admin editing, password reset, accounts, pickers and performance (2026-11-02)

Nothing was run against Supabase except read-only `SELECT`s and log queries. Database
and Edge Function changes are delivered as files for you to apply:

| File | What it does |
|---|---|
| `supabase/migrations/20261102090000_admin_correct_attendance.sql` | Adds `public.admin_correct_attendance(...)` only |
| `supabase/migrations/20261102090100_account_role_and_phone.sql` | Adds nullable `profiles.phone`; role + phone through account creation |
| `supabase/functions/employee-accounts/index.ts` | Deployed v1 + optional `role` / `phone` (only `employeeInput` changed) |

The app is ready for both, behind switches in `lib/core/constants/constants.dart`
(all `false` until applied, so today's app keeps working against today's backend):
`adminAttendanceCorrection`, `accountRoleAndPhone`, `descriptiveEvidenceNames`.

## 1. Admin attendance editing

- **Design (no new table):** the corrected times go to `effective_checkin/checkout` +
  `has_correction` (the columns approved corrections already use). `actual_*` times and the
  evidence events are never changed. The decision is stored as an approved
  `attendance_correction_requests` row (reason, `reviewed_by` = admin, `reviewed_at`), and the
  existing `audit_change` triggers log old/new values with the admin as actor.
- **Security:** `require_actor(true)` (role read from `profiles`, not the client), no
  self-correction, `for update` lock, same time rules as correction approval, a pending
  employee request must be reviewed first. `EXECUTE` revoked from `anon`/`public`.
- **Rules:** closed days only; check-in on the work date and before the shift end; check-out
  ≥ check-in and before midnight (the `auto_close_deadline`). So the date is fixed to the
  work date in the UI; only the times are picked. Overnight shifts don't exist
  (`single_day_shift` constraint).
- **App:** Admin day page → *Edit times* (closed days of other employees) → form with the
  recorded times, current corrected times, time pickers, live worked/overtime preview, reason →
  confirmation showing old → new, hours and overtime → save → back to the day page, reloaded.
  Hours, overtime, history, statistics and summaries all read `verifiedDuration`, which uses
  the effective times, so every screen shows the corrected values.
- Files: `admin_repository.dart`, `supabase_admin_repository.dart` (`correctAttendance`, error
  mapping), `edit_attendance_cubit/*`, `edit_attendance_view.dart`,
  `admin_attendance_day_view.dart`, `admin_errors.dart`, `app_routes.dart`, `app_router.dart`.

## 2. Password reset

**Root cause (from the logs):** the app already sends
`/auth/v1/recover?redirect_to=efsworktracker://reset-password` (seen 2026-11-01). Supabase only
honours `redirect_to` when it is in the Redirect URLs allowlist; otherwise it falls back to the
**Site URL**, which is `http://localhost:3000` by default → the browser opens localhost and fails.
This is dashboard configuration and can't be changed or verified from the app.

**Required Supabase Dashboard settings (Authentication → URL Configuration):**
1. **Redirect URLs:** add `efsworktracker://reset-password` (Android/iOS). For the web build also
   add its origin(s), e.g. `http://localhost:5000/` (dev, fixed port) and your production URL.
2. **Site URL:** your production web URL, or `efsworktracker://reset-password` if there is no web
   app. It must not stay `http://localhost:3000`.
3. **Email template → Reset Password:** keep `{{ .ConfirmationURL }}` (it carries the redirect).
4. Edge secret `PASSWORD_RESET_REDIRECT_URL` = `efsworktracker://reset-password` for resets sent
   by an admin through `employee-accounts`.

**App fixes made:**
- Deep links: Android intent-filter and iOS URL scheme for `efsworktracker://reset-password`
  were already added (earlier work); Flutter's own deep-link routing is off so `supabase_flutter`
  alone handles the link.
- Web: the redirect is now the page's own origin (`Constants.passwordResetRedirectFor`), never a
  hard-coded localhost.
- Expired / already-used / other-phone links: `supabase_flutter` reports them as an *error* on
  the auth stream, which was unhandled (nothing shown). Now `AuthRepository.recoveryLinkFailed`
  turns them into a clear message on the sign-in screen; the other auth streams ignore stream
  errors. Only the error code is kept, never the URL or tokens.
- A valid link opens the password screen titled **Reset your password**; the new password is set
  through the existing `employee-accounts` `change_password` (12–72 bytes, clears
  `must_change_password`).
- Not verified: email delivery and a real link on a device (needs the dashboard settings).
  With the PKCE flow, the link must be opened on the phone that requested it.

## 3. Date and time pickers

- `lib/core/widgets/pickers/app_pickers.dart`: `showAppDatePicker` (clamps the start date),
  `showAppDateRangePicker`, `showAppTimePicker` (follows the phone's 12/24-hour setting).
- `AppTheme`: `datePickerTheme` and `timePickerTheme` from the app's color scheme, radius and
  type (light and dark). Language and RTL come from the app locale.
- All four pickers use them (History, employee correction form, admin date range, admin edit).
  History's date picker was 1900–2100; it is now 2020 → today.

## 4. Role and optional phone

- `profiles` had no phone column (an unused `private.normalize_phone` already defines the format
  `+` country code + 7–14 digits). The migration adds a nullable `phone` with that check.
- Role: the Edge Function accepts `employee`/`admin` (default employee) and stores it only in
  `app_metadata`, which only the service key can write; the trigger assigns it only when the
  creator is an active admin (checked again server-side). Employees have no way to set a role.
  A retried request id can't change role or phone.
- App: the Add Employee form gets the Employee/Admin selector (Employee by default) and an
  optional phone field (spaces/dashes allowed, validated only when filled). The employee page
  shows the phone. Sent only when `Constants.accountRoleAndPhone` is on.

## 5. Performance (found in code; not profiled on a device)

| Found | Change |
|---|---|
| Admin dashboard made 4 sequential requests; employee page 4; day page 3; audit page 2 | Independent reads run in parallel (`(a, b, c).wait`) |
| Dashboard (today + 300 recent days) and employee history (400 days) downloaded every day's evidence events (photo paths, coordinates) and never showed them | Lists use `summaryColumns` without events; only the day page loads evidence |
| Photos decoded at camera resolution (~1080 px) inside 76–220 px previews | `LocalImage` decodes at the shown width; the evidence thumbnail at its 220 px height; full screen keeps the original |
| Sign-in row ("Remember me" / "Forgot password") overflowed by 35 px at 430 px wide | Both labels can shrink and wrap |

No timings were measured (no device or profiler here), so no speed numbers are claimed.

## Tests (this checkout)

| Check | Result |
|---|---|
| `flutter analyze` | 3 issues, all pre-existing deprecation infos in generated `lib/generated/assets.dart` |
| `flutter test` (310) | PASS |
| `test/admin_editing_and_accounts_test.dart` (23) | PASS — correction rules (before/after, other date, midnight, missing, reason, open day), server refusals, double tap, corrected hours/overtime, RPC params and error mapping, Edit button visibility, full edit flow with the time picker and confirmation, phone normalisation/validation, role/phone request body, phone on the employee page, reset redirect (mobile/web), valid/expired reset links, sign-in message, Reset title, picker clamp/RTL/theme/24-hour, router admin-only |
| `flutter build apk --release` | PASS (63.2 MB) |
| iOS build | NOT RUN — Windows host |
| Migrations / Edge Function | NOT RUN — files only, for you to apply |
| Password reset end to end | BLOCKED — dashboard settings above, then a real email on a device |

## To finish

1. Apply `supabase/migrations/20261102090000_admin_correct_attendance.sql`, set
   `Constants.adminAttendanceCorrection = true`.
2. Apply `supabase/migrations/20261102090100_account_role_and_phone.sql`, deploy
   `supabase/functions/employee-accounts`, set `Constants.accountRoleAndPhone = true`.
3. Make the dashboard changes in §2.
4. `flutter pub get && flutter analyze && flutter test && flutter build apk --release`.

## Update 2026-11-02: backend applied, features switched on

**Why the two features were "missing":** they were built but switched off. The required
backend (`admin_correct_attendance`, `profiles.phone`, role-aware account creation,
employee-accounts v2) had only been delivered as files, never applied, so
`Constants.accountRoleAndPhone` and `Constants.adminAttendanceCorrection` stayed `false` and the
role selector, phone field and *Edit times* button were hidden on purpose. The previous report
said this, but not prominently enough.

**Applied with your approval (one-time exception to the read-only rule):**
1. Backup of the three replaced functions: `supabase/backups/20261102_before_role_and_phone.sql`.
2. Migration `admin_correct_attendance` — success.
3. Migration `account_role_and_phone` — success.
4. Edge Function `employee-accounts` → version 2 (`verify_jwt` stays off as in v1) — success.

**Live verification** (as the real users, inside a block that always rolls back; checked
afterwards that nothing persisted):

| Check | Result |
|---|---|
| role `admin` kept, phone `+201012345678` normalised | ✔ |
| no role → `employee`; empty phone → `null` | ✔ |
| invalid role / phone | refused |
| employee calling `backend_validate_employee` (create account) | refused 42501 |
| employee calling `admin_correct_attendance` | refused 42501 |
| admin correcting own day | refused |
| check-out before check-in / empty reason | refused |
| admin corrects anany's 2026-11-01 day to 08:00–16:30 | effective 08:00–16:30, `has_correction`, worked 8h30m, recorded times kept, approved correction row (reviewer = admin, reason), 2 audit rows |
| `anon` can execute the edit function | no |

**App:** both switches set to `true`. Admin → Profile → Admin dashboard → employee → a day →
**Edit times**; Admin dashboard → **Add employee** shows **Employee / Administrator** (Employee
preselected) and **Phone (optional)**.

**Not verified here:** creating a real account and a real edit from a phone (that would create
data in production); please do one of each as described in the manual test steps.

Tests: `flutter analyze` 3 pre-existing generated-file infos; `flutter test` 312 passed;
`flutter build apk --release` passed (63.2 MB). A time-of-day dependent test
(`attendance_session_test` home card, failed between 00:00 and 01:00) was fixed.
