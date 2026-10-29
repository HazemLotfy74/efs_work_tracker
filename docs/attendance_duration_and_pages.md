# Duration Rules, Exceptional Days and Missing Pages

- **Date:** 2026-10-28
- **Database:** read-only **for this work**. I made no database changes.
- **Builds on:** `docs/supabase_auth_audit.md` and `docs/attendance_checkin_checkout.md`.

> ⚠️ **The database was changed by someone else during this work.** It was applied directly (`list_migrations` is empty), between 2026-10-27 and 2026-10-28:
> - `attendance_records` gained **`auto_close_policy`** (text, default `'midnight'`, CHECK `shift_end` | `midnight`) and **`auto_close_deadline`** (GENERATED: `scheduled_end` for `shift_end`, otherwise **midnight after `work_date` in the record's timezone**).
> - A new CHECK constraint, `attendance_auto_close_state`: an auto-closed record has `auto_closed_at = auto_close_deadline` and **no `actual_checkout`**.
> - `private.close_due` closes at `auto_close_deadline`.
> - `public.check_out` accepts a real check-out until the deadline. After it, there's the same silent no-op with the id returned.
> - `request_attendance_correction` / `review_request` accept corrected check-outs up to (but not at) midnight.
>
> Unchanged: `check_in` (check-in still closes at 16:00), the cron job (every minute), the RLS policies, the grants, and the object counts (30 functions, 13 policies, 15 triggers).
>
> The Flutter app now follows the **live** database: closure at `auto_close_deadline`, not `scheduled_end`.

---

## 1. New rules vs. the live database

| Requirement | Live database behavior | Status |
|---|---|---|
| Timer runs past 4 PM until a manual check-out | The session stays open until `auto_close_deadline` (midnight) | **Done.** `isActiveAt(now)` uses the deadline |
| Manual check-out after 4 PM (e.g. 10:00 → 18:30) | `check_out` records it until midnight | **Done.** 8 h regular + observed overtime [tested] |
| Automatic closure at midnight | cron → `close_due` at `auto_close_deadline`. No check-out, evidence or duration is fabricated | **Done.** Shown as *Closed automatically / Needs review*, hours *Not confirmed* |
| Exceptional day for HR review | `auto_closed = true`, `actual_checkout IS NULL`. HR path: `request_attendance_correction` (employee) → `review_request('correction', …)` (admin) → `effective_*` + `has_correction` | **Display done.** Request and review screens are not built yet (§6) |
| Regular = min(elapsed, 8 h), overtime = elapsed − 8 h | No duration or overtime columns. Approved overtime only in `overtime_requests.status = 'approved'` | **Done in Flutter** (`WorkDuration`). Observed ≠ approved |
| Unverified time isn't counted | Previously the app showed an auto-closed day as check-in → 16:00 (≈ 8 h) | **Fixed.** Now shown as *Not confirmed / Needs review* |
| Breaks | No break columns | Nothing is deducted |
| Roles | `profiles.role` ∈ {`employee`, `admin`}. No HR role | An admin's RLS reads everyone's rows, so the app filters on its own id |
| Lateness | `late_minutes` (generated) = max(0, minutes after 08:00 − grace) | Shown as the database computes it. It is schedule-based, not duration-based |

Inspected for this work (read-only): cron job and run history, all functions and triggers listed above, the `overtime_requests` RLS policy, column metadata, and row counts only.

---

## 2. One duration rule

- `domain/entities/work_duration.dart`, `WorkDuration(worked)`:
  - `regular` = min(worked, 8 h).
  - `overtime` = max(0, worked − 8 h), **observed only**.
  - `shortfall` = max(0, 8 h − worked).
  - Negative input is clamped to 0.
- `AttendanceSessionEntity`:
  - `isVerified`: a manual check-out, or an admin-approved correction with an effective check-out.
  - `needsReview`: auto-closed, no check-out, not corrected.
  - `verifiedDuration`: `null` unless verified. **Never 8 h by assumption.**
  - `durationAt(now)`: the live elapsed time (now − recorded check-in) while active, otherwise `verifiedDuration`. It's recalculated from timestamps, so restarts and backgrounding don't affect it. The 1-second tick is display only.
  - `statusAt(now)`: `inProgress` / `completed` / `needsReview`. The one status used on every screen.
  - `earlyLeave`: the shortfall from 8 h (it used to be "before 4 PM").
  - `endsBeforeRegularHours`: the server will close the day before 8 h pass for this check-in, and the UI warns about it.
- Removed: `regularEnd` (counted an auto-closed day up to 16:00) and `ShiftEntity.earlyLeaveFor` (a 4 PM rule).

---

## 3. Screens

| Screen | Before | Now |
|---|---|---|
| Home card | Auto-closed day showed ≈ 8 h | *Not confirmed* + *Needs Review*. An active session warns when the server closes before 8 h. A verified day shows observed overtime, labeled as not approved |
| Home "Today's overview" | Static `-` / `0m`. "View details" pushed the raw `/attendance/:id` pattern (broken) | Real regular hours (or *Not confirmed*), lateness, early leave (shortfall) and **approved OT** from `overtime_requests` (`-` if unreadable, never a made-up 0). "View details" opens today's record, hidden before check-in |
| Review step | Duration preview | Same rule, plus an observed-overtime row; early departure = shortfall from 8 h |
| Check-out success | Worked time | Verified time only |
| **History tab** | Placeholder | Own records, newest first (60). Status badge, times, worked or *Not confirmed*. Pull to refresh; empty, error and loading states. Reloads after a check-in or check-out |
| **Attendance details** | Static sample (2025 date, "8:07 Am", a fixed address) | Loads the record by id (own only, *not found* otherwise). Status header, the review warning for unconfirmed days, work summary, events (check-in with evidence and lateness; check-out with evidence, or the system auto-close event flagged for admin review) |
| **Profile tab** | Placeholder | Name, initials, role, employee code, username, email, today's schedule, **sign out**. No phone or photo: the database has neither |

Files:
- **New:** `attendance_session/domain/entities/work_duration.dart`, `attendance_session/presentation/widgets/attendance_day_status_text.dart`, `history/**` (view, body, tile, cubit), `home/presentation/manager/attendance_details_cubit/*`, `profile/**`.
- **Modified:** the session entity and model, shift entity and model, the repository interface + Supabase + in-memory implementations, `DatabaseServices.getData` (optional `orderBy` / `descending` / `limit`), the Home card / overview / summary / status header / events widgets, the details view, Review, Success, the router, ARB files and tests.

---

## 4. Security

- All reads go through the existing RLS. History, details and approved overtime **always filter on `employee_id = auth uid`**, because the admin policy would otherwise return every employee's rows [tested].
- No writes were added. The writes are still only `check_in` / `check_out`.
- The admin role is shown on the profile, but it isn't used as a security boundary anywhere.

---

## 5. Tests actually run

| Command | Result |
|---|---|
| `dart format` (changed files only) | Done. No unrelated files touched |
| `flutter analyze` | **0 errors.** 1 warning + 3 infos, all in files I didn't change |
| `flutter test` | **147 passed, 0 failed** |

New tests cover:
- The duration table from the requirements (08→16, 09→17, 10→18, 10→18:30, 10→19).
- Short days and negative input.
- Live duration from the recorded check-in.
- A closed day having no hours; an approved correction confirming the hours.
- A shift that ended before the server's close counting as needs review.
- History and details scoped to the employee; approved overtime summed; unreadable overtime treated as unknown.
- History page: empty, error, and a day needing review.
- Details page: a closed day, a verified day with approved OT, not found.
- Both smoke suites now also render History and Profile (overflow at 1.0× / 1.3×, dark theme).

A real overflow in the details events row (long text, large fonts) was found and fixed.

**Not run:** database or integration tests (production only), and on-device runs.

---

## 6. Not implemented (needs a database change, or is a separate feature)

| Item | Why |
|---|---|
| HR review of an auto-closed day *in the app* | The backend exists (correction request + admin review, now up to midnight), but it needs an employee form and an admin queue |
| Check-in after 16:00 | `check_in` still refuses it (CHECK `actual_checkin < scheduled_end`). Unchanged by the external update |
| Orphaned selfies | The bucket has no DELETE policy |
| Overtime and cash request screens | UI only today; `request_overtime` / `request_expense_advance` exist and aren't connected |
| Notifications, Settings, Language, Privacy | No backend data (notifications), or out of scope (locale is fixed to `ar` in `main.dart`) |
