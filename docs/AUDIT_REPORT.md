# Audit report — EFS WorkTrack (2026-11-10)

Scope: the Flutter app in this repository and the live Supabase project
`fotxyzooanysjthovpfz`, inspected **read-only** (metadata and `SELECT` queries, Supabase
advisors). No database object or row was changed during this audit.

Earlier, narrower reports stay valid and are not repeated here:
`full_app_audit.md`, `project_security_review_2026-10-31.md`, `supabase_auth_audit.md`,
`release_white_screen_fix.md`.

Legend: **Confirmed** = reproduced or read in code/DB. **Risk** = possible problem, not
observed. **Gap** = requirement from the 2026-11-10 brief that has no implementation yet.

## 1. What exists today

| Area | State |
|---|---|
| Auth | Supabase email/password, forced first password change, reset by deep link, admin-created accounts through the `employee-accounts` Edge Function |
| Attendance | Manual check-in/out with GPS + front-camera selfie, server time (`clock_timestamp()`), one record per employee per day (`UNIQUE(employee_id, work_date)`), advisory lock per employee |
| Auto-close | `pg_cron` every minute → `private.close_due`; sets `auto_closed`, keeps `actual_checkout` NULL (constraint `attendance_auto_close_state`) |
| Overtime | Calculated in the app (`WorkDuration`): 8 h regular, the rest overtime, from the **effective** check-in. No fixed 4 PM threshold. The old `overtime_requests` table is unused (0 rows), its screens were removed |
| Corrections | Employee requests (`request_attendance_correction`), admin approval/rejection (`review_request`), admin direct edit (`admin_correct_attendance`). Original `actual_*` times and evidence events are never overwritten |
| Cash requests | `request_expense_advance`, reviewed through `review_request` |
| Admin | Dashboard, employee details, day evidence (signed URLs), audit history, add employee (role + optional phone), activate/deactivate, schedule assignment |
| Audit | `audit_change` triggers on the business tables → `audit_logs` (admin-readable) |
| i18n | gen-l10n English + Arabic, RTL |
| Tests | 316 automated tests (unit + widget), all passing on 2026-11-10 |

## 2. Findings

### P0 — critical

| ID | Finding | Status |
|---|---|---|
| P0-1 | **Release APK white screen** — R8 removed `shared_preferences_android` methods called through JNI; `Supabase.initialize` threw before `runApp`. | **Fixed 2026-11-02** (keep rules, verified on a Redmi Note 8 Pro, see `release_white_screen_fix.md`) |
| P0-2 | **iOS camera permission text missing.** `ios/Runner/Info.plist` had `NSLocationWhenInUseUsageDescription` but no `NSCameraUsageDescription`, while the selfie step calls `ImagePicker.pickImage(source: ImageSource.camera)` (`selfie_page_view.dart:29`). iOS terminates an app that opens the camera without it, so **no iOS user could check in**. | **Fixed today** (key added). Not verified on a device: needs a macOS/Xcode build |

No data-corruption or authorization bypass was found. Every write goes through a
`SECURITY DEFINER` function that calls `private.require_actor(...)`. Tables have RLS with
SELECT-only policies (no client INSERT/UPDATE/DELETE). Self-review is blocked twice: in
`review_request` and by `*_no_self_review` check constraints.

### P1 — broken core functionality / missing core requirement

| ID | Finding | Evidence | Fix |
|---|---|---|---|
| P1-1 | Admins could not send their own cash requests (app-only restriction; backend allowed it). | `AppRouter._employeeOnlyRoutes`, `home_view_body.dart` `if (!isAdmin)` | **Fixed today**. Self-approval still impossible (backend). 3 active admins exist, so another admin can review |
| P1-2 | **Gap — no dynamic permissions.** Authorization is one column, `profiles.role ∈ {employee, admin}`, read by `private.is_admin()` in every RLS policy and `require_actor(true)` in every admin RPC. | `profiles_role_check`, `pg_policies` | Needs new tables + RPCs + policy changes → DB proposal, approval required (plan §3) |
| P1-3 | **Gap — no leave management.** No leave/holiday tables, functions or screens. | `list_tables` (9 tables, none for leave) | The HR workbook will mark leave as "not recorded" until a leave feature is approved; never inferred |
| P1-4 | **Gap — correction requests cannot be cancelled.** Status check allows only `pending/approved/rejected`; no cancel RPC. | `attendance_correction_requests_status_check` | DB change (new status + `cancel_correction_request`) |
| P1-5 | **Gap — no overtime approval.** Overtime is calculated, never approved, so "approved / payroll-eligible overtime" has no source. | `overtime_requests` unused; no approval column on `attendance_records` | Business decision needed (see questions) |
| P1-6 | **Gap — no departments / job titles.** `profiles` has neither, so HR report columns "Department" and "Job title" are empty. | `information_schema.columns` | DB change, optional |
| P1-7 | **Gap — no HR reports / Excel export.** | no reporting module | App-side feature; can read existing tables under the admin RLS policies without DB changes (plan §4) |

### P2 — security hardening, performance, UX

| ID | Finding | Evidence | Fix |
|---|---|---|---|
| P2-1 | Leaked-password protection (HaveIBeenPwned) is off. | Supabase security advisor | Dashboard → Auth → Passwords (owner action) |
| P2-2 | 11 `SECURITY DEFINER` RPCs executable by `authenticated`. | Supabase advisor 0029 | **Intended** (they are the write API and each checks the caller). Keep `anon` revoked; re-check after every new RPC |
| P2-3 | Arabic text rendered in the phone's system font: Manrope has no Arabic glyphs (verified by reading its `cmap`: no U+0627). | `assets/fonts/Manrope-*.ttf` | **Fixed today**: Cairo bundled, applied through the theme |
| P2-4 | Letter spacing applied to Arabic text pulls joined letters apart. | `AppTextStyles` roles with `letterSpacing` | **Fixed today**: removed in RTL (theme + `context.tracked`) |
| P2-5 | `google_fonts` declared but never imported. | `grep` | **Removed today** |
| P2-6 | No CI. | no `.github/` | Plan stage 7 (GitHub Actions: format, analyze, test, build) |
| P2-7 | Check-in is refused before shift start and after shift end (`check_in`). Someone arriving at 16:30 cannot check in at all. | `public.check_in` | Existing rule, kept. Confirm it is wanted |
| P2-8 | `pg_cron` auto-close runs every minute. | `cron.job` | Cheap at this size (indexed, few rows); fine |
| P2-9 | 8 unused indexes. | performance advisor (INFO) | Keep: the data set is tiny (≤13 rows per table), usage stats are meaningless yet |

### P3 — minor

- `lib/generated/assets.dart` uses deprecated `flutter_svg` color params (3 analyzer infos; generated file).
- The `notifications`, `settings` and `attendance_history` feature folders have no views.
- `overtime_requests` + `request_overtime` remain in the DB, unused since automatic overtime.
  Leave them (no harm, history kept) until a cleanup migration is approved.

## 3. Business rules verified

| Rule | Where | Result |
|---|---|---|
| Server time for attendance | `check_in` / `check_out` use `clock_timestamp()` | ✔ |
| No duplicate sessions | `UNIQUE(employee_id, work_date)`, advisory lock | ✔ |
| Overtime after 8 worked hours, not at 4 PM | `WorkDuration` (app), tests | ✔ |
| Auto-closed day ≠ manual checkout | `actual_checkout` stays NULL, `auto_closed=true`, flagged for review in the app | ✔ |
| Evidence never overwritten | corrections write `effective_*` only; constraint `attendance_records_check5` | ✔ |
| No self-approval | `review_request` + check constraints | ✔ |
| Admin may correct own attendance via request | `request_attendance_correction` uses `require_actor()` (any active user) | ✔ (reviewed by another admin) |

## 4. Not verified

- iOS runtime (no macOS here).
- Behaviour under real network loss on a device.
- Performance numbers (no profiling run).
