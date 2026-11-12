# Implementation plan (2026-11-10)

Order follows risk: correctness and security first, then admin/HR features, then design,
performance and release. Items marked **DB** need a database change: a versioned migration
file is written and explained first, and nothing is applied without your explicit approval.

## Done on 2026-11-10

- iOS camera permission text (P0-2).
- Admins can send their own cash requests (P1-1); self-review still blocked by the DB.
- Cairo bundled and applied through the theme for Arabic; no letter spacing in Arabic;
  unused `google_fonts` removed (P2-3…P2-5). 316 tests pass.
- AUDIT_REPORT.md, ARCHITECTURE.md, this plan.

## Stage 3 — core reliability

| # | Work | DB | Depends on |
|---|---|---|---|
| 3.1 | Correction cancel: status `cancelled`, `cancel_correction_request(id)` (owner, pending only), app button | **DB** | — |
| 3.2 | Overtime approval model (see question 1) | **DB** | decision |
| 3.3 | Hide approve/reject on own items in every review list (already done for cash) and show "needs another reviewer" | app | — |

## Stage 4 — admin and HR

| # | Work | DB | Notes |
|---|---|---|---|
| 4.1 | **Permissions** — app done (switched off), migration written, NOT applied; see PERMISSIONS.md. Design: `permissions` catalog, `role_permissions` (defaults per role), `user_permissions` (grant/revoke per user), `private.has_permission(code)`; RPCs `admin_set_user_permissions`, `get_my_permissions`; replace `is_admin()` / `require_actor(true)` checks one capability at a time; audit via the existing trigger | **DB** | Default deny; `employees.manage_permissions` cannot be self-granted; a grantor can only grant what they hold; `admin` role keeps all permissions so nothing breaks on day one |
| 4.2 | Permission management screen (employee → role, inherited vs. individual permissions, review diff, save, history from `audit_logs`) | app | after 4.1 |
| 4.3 | **HR reports + Excel** — DONE 2026-11-11 (see HR_REPORTS_SPECIFICATION.md); export audit + `reports.export` permission wait for 4.1 | app | — |
| 4.4 | Leave management (types, requests, approval, holidays) | **DB** | only if you want it now (question 2) |
| 4.5 | Departments / job titles on `profiles` | **DB** | optional (question 3) |
| 4.6 | Admin dashboard regrouping: Attendance · Employees · Financial requests · HR reports | app | uses the existing palette and the profile-card style from your screenshot |

## Stage 5 — design

- Consistent loading / empty / error states, dialogs and snackbars (shared components exist:
  `AppDialog`, `showAppSnackBar`).
- Small-screen and text-scale pass on every screen (widget tests at 320 px and 1.3×).

## Stage 6 — performance

- Measure first (`flutter build apk --analyze-size`, DevTools on the device), then act.

## Stage 7 — QA and release

- GitHub Actions: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`,
  `flutter build apk --release`.
- Real Android upload key; iOS build on macOS + device test for camera/location.

## Open questions (only what the code cannot answer)

1. **Overtime approval:** should calculated overtime need HR approval before it counts
   as payroll-eligible (recommended: yes, approve per day in the review screen), or is
   all calculated overtime payable?
2. **Leave:** build leave management now (types: annual, sick, emergency, unpaid, other),
   or ship the HR workbook first with the leave sheet marked "not recorded"?
3. **Departments / job titles:** add them to employee profiles now?
4. **Late check-in:** today the server refuses check-in after the shift end (16:00). Keep it?
