# Status of the "Enterprise-Level Development" brief (2026-11-12)

Live database inspected read-only first (functions, policies, foreign keys, schedules).

## Done in the app (no database change)

| Item | Result |
|---|---|
| Check-in button shown before the window opens (reported bug) | Root cause: the app only checked "shift not over", never "window open". Now one rule — `AttendanceSessionLoaded.checkInAt` — gives open / not yet open / closed / day off / already checked in, by the same rule the server applies today (shift start → shift end). Outside the window the button is **disabled with the reason** ("Check-in opens at 8:00", "check-in is closed"). Times are compared as instants, so the phone's timezone can't shift them; the server re-checks with its own clock |
| Too-early check-in reported as "invalid location" | The server refuses with code 22023, which the app mapped to a GPS error. Now mapped to "Check-in has not opened yet"; also ready for the new window messages |
| "Check In Now" label overflowed on 360 px phones | Shared `TextIconWidget` label now wraps |
| APK size | Measured: fat 65.4 MB → **22.9 MB** per phone with split APKs / App Bundle; timezone data trimmed (23.1 → 22.9 MB arm64). See PERFORMANCE_REPORT.md |
| Tests | `test/check_in_window_test.dart` (9): boundaries 07:59:59 / 08:00 / 15:59 / 16:00, timezone-independence, day off, already checked in, error mapping, card states incl. Arabic at 360 px |

## Written, waiting for your approval (database)

**Check-in window 07:00–11:00** — `supabase/migrations/20261112090000_check_in_window.sql`
(rollback `supabase/backups/20261112_before_check_in_window.sql`, dry run
`supabase/verify/20261112_check_in_window_dry_run.sql`).
- Window stored per schedule (`checkin_opens` 07:00, `checkin_closes` 11:00), enforced by
  `check_in` with the **server clock** in Africa/Cairo (DST handled by PostgreSQL).
- `07:00:00 ≤ check-in < 11:00:00` — 11:00 exactly is refused.
- New `get_check_in_window()` returns the server time and today's window, so the app's button
  follows the server even when the phone clock is wrong (app wiring after the migration).
- Unchanged: lateness from the 08:00 shift start + grace (a 07:00 check-in is on time), 8 regular
  hours from the actual check-in, check-out, overtime, midnight auto-close.
- Procedure (after the 2026-11-11 incident): dry run in a transaction that always rolls back →
  apply → verify as real users → only then switch the app over.

## Needs your decision before building

1. **Delete employee.** Every table linking to an employee blocks deletion (attendance, requests,
   corrections, the login account). Recommended: *Archive* for anyone with history (login
   permanently blocked, hidden from lists, records kept) and real deletion — through the
   `employee-accounts` Edge Function with server credentials — only for accounts that never
   recorded anything. Agree?
2. **"Missing check-in" corrections.** Today a correction always edits an existing day. A day
   with no check-in has no record and no photo/location evidence. Should an approved request
   **create** that day (marked "created by correction, no evidence"), or should admins only mark
   such days as present in reports?
3. **Edit employee.** Today only active/inactive and schedule can change. Which fields may an
   admin edit: name, phone, employee code, role? (Email changes go through Supabase Auth and
   would need the Edge Function.)

## Already in place (verified)

- **Suspension** is enforced by the server: inactive accounts can't sign in or refresh tokens
  (auth hook), and every read/write checks `is_active` — a suspended user's open session stops
  working at its next request. Admins can suspend/reactivate from the employee page.
- **Correction security:** employees see only their own requests; self-review is blocked in the
  function and by table constraints; corrections never overwrite recorded times or evidence.
