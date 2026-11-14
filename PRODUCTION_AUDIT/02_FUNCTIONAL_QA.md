# 02 — Functional QA and business logic (2026-11-12)

**How this was tested.** By automated tests against fakes that mirror the database functions, and by
reading the live function definitions. **Nothing was exercised with real accounts or on a device**:
the only database is production (writes need your approval) and no phone was attached.

## Attendance rules (as the live database enforces them) [read]
| Rule | Where enforced |
|---|---|
| Identity = the session's user; the client never sends an employee id | `require_actor()` in every function |
| One record per employee per work date | UNIQUE `(employee_id, work_date)` + per-employee advisory lock |
| Work date in the schedule's timezone (Africa/Cairo, DST-aware) | `check_in` |
| Check-in only on a scheduled weekday, from shift start (08:00) until shift end (16:00) | `check_in` |
| Check-out any time until `auto_close_deadline` (midnight); never twice | `check_out`, row lock |
| Not checked out by midnight → auto-closed, no fabricated check-out, hours unconfirmed | cron `attendance-auto-close` (1,440 runs / 24 h, 0 failed) |
| Lateness = minutes after shift start minus grace (15) | generated column `late_minutes` |
| 8 regular hours from check-in; the rest is observed overtime | app (`WorkDuration`), tested |
| Corrections keep the recorded times and evidence; set effective times | `review_request`, `admin_correct_attendance` |
| GPS range and an uploaded, owned selfie required | `check_in` / `check_out`, `assert_selfie` |

## Coverage by automated test (389 passing) [run]
| Area | Covered |
|---|---|
| Sign-in, sign-out, forced password change, reset link, route guard | yes |
| Check-in / check-out, duplicates, lost response, wrong phone clock, other device | yes |
| Check-in window boundaries (07:59:59, 08:00, 15:59, 16:00), day off, timezone independence | yes |
| Duration table (8 h + overtime), short days, auto-closed days never counted | yes |
| History, details, corrections (request, review, admin edit) | yes |
| Cash requests (submit, list, review, self-review blocked) | yes |
| Admin: employees, add employee, suspend, schedule, audit, edit, email change | yes |
| Permissions, assignment, delegated review | yes |
| HR report figures and Excel workbook | yes |
| Arabic/English, small screens (320–430 px), text scale 1.3×, dark theme | yes |
| Notifications inbox and push registration | **partly** (teammate's feature; not audited in depth) |

## RBAC matrix (from function and policy definitions) [read]
| Action | Employee | Delegated reviewer | Admin | Inactive / must change password |
|---|---|---|---|---|
| Own profile, attendance, requests, notifications | read | read | read | **nothing** |
| Other employees' data | no | only request rows assigned to them | all | nothing |
| Check-in / out, submit requests | yes | yes | yes | no |
| Review cash / corrections | no | assigned only, never own | all except own | no |
| Suspend, edit, schedule, grace, permissions, assign | no | no | yes (employee accounts only) | no |
| Create accounts, reset passwords | no | no | yes (Edge Function) | no |
| Audit log | no | no | read | no |

**Not verified by acting as each role on the database**: an as-user read test (transaction always
rolled back) was blocked by the session's safety controls. See 03 for the static evidence.

## Not supported by the product today (not defects)
Breaks, leave/absence, public holidays, overnight shifts, offline queueing of check-ins (a check-in
needs the server; the app shows a clear error and never fakes success).

## Findings
| ID | Sev | Finding | Status |
|---|---|---|---|
| F-1 | P1 | No end-to-end run of sign-in → check-in → check-out → correction → review with real accounts on a release build | **Open — required before launch** |
| F-2 | P2 | Check-in is refused after 16:00; an employee who arrives later cannot record the day | Open — confirm it is intended |
| F-3 | P2 | Lateness subtracts the grace (20 min late = 5 recorded) | Open — confirm it is intended |
| F-4 | P3 | 6 selfies in Storage belong to no attendance event (failed saves); the bucket allows no delete | Open — needs a server-side cleanup |
