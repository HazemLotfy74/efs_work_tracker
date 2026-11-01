# Release fixes report (2026-11-01)

No database object, policy, function, Edge Function, secret or row was changed. Supabase
was read only (catalog queries and logs). Backend changes that are needed are written up,
not applied, in `docs/proposal_roles_and_cash_guard.md`.

## 1. Release APK

- **Build:** `flutter build apk --release` → PASS, `build/app/outputs/flutter-apk/app-release.apk` (60.9 MB).
  AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, Java 17, Flutter 3.47.6.
- **Configuration checked:** `INTERNET` and location permissions are in the *main* manifest
  (release has them, not only debug); Supabase URL/key are compile-time constants (no `.env`
  that a release build could miss); fonts are bundled; map tiles send a user agent; no
  debug-only code paths (`kDebugMode`/`assert`) in `lib/`.
- **Evidence from a real device:** Supabase logs for 2026-11-01 show a phone client
  (`Dart/3.13 (dart:io)`) signing in, uploading a selfie, calling `check_in`, creating an
  employee account through `employee-accounts` (201), and the new employee changing the
  password, all with HTTP 200/201. So connectivity, auth, check-in and account creation
  work on a device. Whether that phone ran the release or a debug build can't be told from
  the logs.
- **Not verified here:** no device or `adb` is available in this environment, so the APK
  was not installed or run. No release-only defect was found in code or logs; if the APK
  still misbehaves, the exact symptom (screen, message, or `adb logcat` output) is needed.
- Release builds are still signed with the **debug key** (`signingConfig = debug` in
  `android/app/build.gradle.kts`). Fine for installing and testing; a real upload key is
  needed for the Play Store.

## 2. Check-in card: gray inner section

- **Root cause:** `BrandStatusBadge` always used `brandSurfaceBadge` (gray `neutral600`),
  whatever the attendance state.
- **Fix:** `BrandBadgeTone` (`neutral` / `active` / `warning`). The badge is the theme's
  primary green while checked in, neutral before check-in and after check-out, and the
  warning colors when the day closed automatically. Theme colors only; dark theme included.
- Files: `home/presentation/widgets/brand_status_badge.dart`, `attendance_session_card.dart`.

## 3. Admin early-departure review

- **Root cause:** the admin board only flagged days *closed automatically* (missing
  check-out). An early check-out has confirmed hours, so its status was "Checked Out" and
  nothing compared the check-out with the shift end.
- **Fix:** `AttendanceSessionEntity.leftEarly` / `leftEarlyBy`: actual check-out strictly
  before the record's own `scheduled_end` (copied by the server from the employee's assigned
  schedule at check-in, so it is per schedule and never hard-coded). Compared as instants, so
  timezone/date can't shift it. A missing check-out is *not* an early departure.
- Admin dashboard: a "Left early" count for today, today's row shows a "Left early" badge,
  and an **"Early departures to review"** section lists recent ones (last 300 records) with
  employee, date, shift, actual check-out, shift end and how early, in the day's timezone.
  Employee history shows the same badge.
- Overnight shifts: not possible in this database (`schedule_days` constraint
  `single_day_shift: starts_at < ends_at`). Evening shifts are covered by tests.
- Existing duration/overtime logic is unchanged (the employee-side "Early leave" tile keeps
  the 8-hour rule).
- Files: `attendance_session_entity.dart`, admin `admin_repository.dart`,
  `supabase_admin_repository.dart` (`getRecentDays`), `admin_dashboard_cubit/*`,
  `admin_dashboard_view_body.dart`, `admin_day_status.dart`.

## 4. Role when creating accounts

- **Root cause:** the backend can't do it. `employee-accounts` rejects a `role` field, the
  `auth.users` trigger always inserts `employee`, and there is no role-changing RPC.
- **Done in the app:** an Employee/Admin selector (Employee by default), `NewEmployeeDraft.role`,
  and the repository sending `role`, all behind `Constants.roleOnAccountCreation = false`.
- **Needs your approval:** the exact Edge Function diff and SQL are in
  `docs/proposal_roles_and_cash_guard.md`. After it is applied, set the constant to `true`.
- Security: the role is set only server-side by an admin-verified path; employees can't
  elevate themselves (no client write to `profiles`, RLS is read-only).

## 5. Dialogs and SnackBars

- New `lib/core/widgets/feedback/`: `AppMessageType` (success/error/warning/info, icons and
  theme colors), `showAppSnackBar` (floating, icon, wraps long Arabic text, replaces the
  current SnackBar so repeated taps don't stack), `AppDialog` + `AppDialogAction` +
  `showAppConfirmationDialog`.
- Theme: `dialogTheme`, `snackBarTheme`, `textButtonTheme` in `AppTheme`.
- Every SnackBar in the app (5) and the review dialog now use these.
- Also fixed: `CustomRequestRow` overflowed by 17 px on a 430 px-wide screen (text couldn't
  shrink); it now wraps.

## 6. Cash requests hidden for admins

- Home hides "Need a cash advance?" for admins; the router sends admins away from `/cash`
  and `/new-cash`. Employees are unchanged.
- **Direct API:** `request_expense_advance` only checks that the user is active, so an
  admin could still call it directly. The database guard is in the proposal (not applied).

## Tests (this checkout)

| Check | Result |
|---|---|
| `flutter analyze` | PASS — 3 pre-existing infos in generated `lib/generated/assets.dart` |
| `flutter test` (249) | PASS |
| `test/release_fixes_test.dart` (15) | PASS — early departure (morning/evening/at end/missing check-out), dashboard list with times, badge colors, admin cash visibility + routes, SnackBar/dialog, role selector & request body |
| `flutter build apk --release` | PASS |
| Install/run the APK on a device | NOT RUN — no device/adb here |
| Leave requests, notifications | NOT APPLICABLE — not in this app/database |

## Installing and testing the release APK

1. Copy `build/app/outputs/flutter-apk/app-release.apk` to the phone (or
   `adb install -r build/app/outputs/flutter-apk/app-release.apk`).
2. Allow "install unknown apps" for the file manager if asked; uninstall any older build
   signed differently first.
3. Employee: sign in → check in (08:00–16:00 Cairo, location + selfie) → the Home pill turns
   green → check out before 16:00 → as admin, Profile → Admin dashboard shows the employee
   under "Early departures to review" with the check-out and shift end.
4. Admin: the Home screen has no cash card; `/cash` is unreachable.
5. If anything fails, run `adb logcat -s flutter` while reproducing and share the output.
