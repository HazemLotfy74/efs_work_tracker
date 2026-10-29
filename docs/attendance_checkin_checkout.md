# Check-in & Check-out — Strict Database Preservation

- **Date:** 2026-10-27
- **Project:** `employee-attendance` (`fotxyzooanysjthovpfz`)
- **Rule:** the database is read-only for this work. The Flutter app adapts to it.

Labels: **[verified]** inspected or run. **[tested]** an automated test covers it. **[untested]** reasoning only.

---

## 1. Database objects used (unchanged)

| Object | How the app uses it | Access (verified) |
|---|---|---|
| `profiles` | Your own row → `schedule_id` (FK `profiles_schedule_id_fkey`) | `SELECT`. RLS `profile_read`: `is_active() AND (id = auth.uid() OR is_admin())` |
| `work_schedules` | Embedded through the FK → `timezone`, `grace_minutes` | `SELECT`. RLS: `is_active()` |
| `schedule_days` | Embedded through `schedule_days_schedule_id_fkey` → `weekday`, `starts_at`, `ends_at` | `SELECT`. RLS: `is_active()` |
| `attendance_records` | Today's row: `employee_id = uid`, `work_date = today in the schedule timezone` | `SELECT`. RLS `attendance_read`: own rows, or admin |
| `attendance_events` | Embedded through `attendance_events_attendance_id_fkey` → evidence and selfie path | `SELECT`. RLS `event_read`: through the owned record |
| `public.check_in(lat, lng, accuracy, selfie_path)` | The only check-in write | `EXECUTE` for authenticated, SECURITY DEFINER |
| `public.check_out(attendance_id, lat, lng, accuracy, selfie_path)` | The only check-out write | `EXECUTE` for authenticated, SECURITY DEFINER |
| Storage `attendance-evidence` | Selfie upload to `<uid>/<uuid>.<ext>` | INSERT policy `attendance_selfie_upload`. No UPDATE or DELETE |
| cron `attendance-auto-close` | Not called by the app. The app only displays its result | `* * * * *` → `private.auto_close_attendance()` |

### Inspected for this work [verified]
- Columns, types and nullability of the five tables.
- `authenticated` grants: `SELECT` only.
- All 9 `public` RLS policies and the 4 Storage policies.
- Full definitions of `check_in`, `check_out`, `close_due`, `auto_close_attendance`, `require_actor`, `is_active`, `is_admin`, `assert_selfie`, `request_attendance_correction` and `review_request`.
- Triggers, cron job history (8,084 runs, 0 failures) and schedule data: Sun–Thu, 08:00–16:00, `Africa/Cairo`, grace 15.

### Not inspected
Auth dashboard settings (whether the access-token hook is enabled, JWT expiry). The MCP doesn't expose them.

### Final database check
After all the work:
- 30 functions, 13 policies, 14 triggers in `public`.
- `check_out` is still the original definition, and `get_today_attendance` does not exist.
- 0 attendance rows, 0 event rows.

These are the same numbers as the original audit. **No database write of any kind was made.**

---

## 2. Database changes

**None.** An earlier draft migration (`supabase/migrations/…`) was **never applied** and has been **deleted** from the repository. The diff contains no `.sql` files, migrations or schema changes. [verified]

---

## 3. Files

**New**
- `core/errors/attendance_errors.dart`: `AttendanceFailure`.
- `core/services/storage_services.dart`, `core/services/supabase_storage_services.dart`: upload. Never overwrites; "already exists" counts as success.
- `attendance_session/data/models/shift_model.dart`: builds the shift from a `schedule_days` row in the real timezone.
- `attendance_session/data/models/attendance_session_model.dart`: a record plus its embedded events.
- `attendance_session/data/repositories/supabase_attendance_repository.dart`
- `attendance_session/presentation/widgets/attendance_failure_text.dart`
- `test/attendance_supabase_test.dart`: 31 tests.

**Modified**
- `domain/entities/shift_entity.dart`, `attendance_session_entity.dart`: server instants, auto-close, effective times, `isActiveAt`.
- `domain/repositories/attendance_repository.dart`: `getToday()` (shift and session together).
- `data/repositories/in_memory_attendance_repository.dart`: typed failures, used by tests.
- `manager/attendance_session_cubit/*`: account tracking, save guard, stale-result guard.
- `review_page_view.dart`, `prepare_view_page.dart`, `attendance_success_view_body.dart`, and Home's `today_attendance_card.dart`, `attendance_session_card.dart`, `not_checked_in_custom_container.dart`.
- `core/services/getit_services.dart`, `core/constants/constants.dart`, `main.dart`.
- `l10n/app_en.arb`, `app_ar.arb` + generated files.
- `pubspec.yaml` / `pubspec.lock`: **adds `timezone: ^0.11.2`.** It is required to find "today" in `Africa/Cairo`, which has DST, without a new database function.
- `test/attendance_session_test.dart`, `test/helpers/app_providers.dart`.

**Formatter-only changes, unrelated:** `dart format` re-wrapped 15 files in `cash_request/`, `overtime/`, `attendance_details_view_body.dart` and `test/date_time_test.dart`. There is no code change in them. Revert them if you prefer a smaller diff.

---

## 4. How it works with the existing schema

**Loading today** (`getToday`):
1. Read `profiles` (own row) with `work_schedules(timezone, grace_minutes, schedule_days(...))` embedded.
   - No row → `accountNotReady`. RLS hides the row while the account is inactive or must change its password.
   - No schedule → `noSchedule`.
2. Work date = the device's current instant converted to the schedule's timezone (IANA rules). This is the same rule `check_in` uses.
3. Today's shift = the `schedule_days` row for that weekday (Postgres `dow`). The instants are built from wall-clock time, correct across DST [tested]. No row → day off.
4. Read `attendance_records` for `(uid, work_date)` with `attendance_events` embedded.
   - More than one row, or missing required values → `unknown`, never "not checked in" [tested].

**Check-in:**
1. Home offers it only on a working day, before the shift end, with no record yet.
2. The selfie is uploaded once.
3. Call `check_in`. The server sets the employee, the time and lateness, and enforces uniqueness.
4. Read the record back. The UI shows that.

**Check-out:**
1. Offered only while `isActiveAt(now)`: no checkout, not auto-closed, and before `scheduled_end`.
2. The repository re-checks this **before uploading or calling anything**.
3. Call `check_out` with the record id from today's read.
4. Read back. **Success only if the record now has a check-out event with this selfie.** If the database auto-closed it instead, the result is `closedAutomatically`, not success [tested].

---

## 5. State and duplicates

| Case | Handling | Guaranteed by |
|---|---|---|
| Double tap | Review `_isSaving` + cubit `busy` [tested] | App |
| Two check-ins (any source) | `UNIQUE(employee_id, work_date)` + advisory lock → `23505` → reconcile [tested with fake] | **Database** |
| Two check-outs | `FOR UPDATE` + "Checkout was already recorded" → reconcile [tested with fake] | **Database** |
| Lost response or timeout | Read back. A matching selfie path means it was saved; otherwise the original error [tested] | App + DB unique `selfie_path` |
| Saved, read-back failed | `outcomeUnknown`, stay on Review. A retry is matched by selfie [tested] | App |
| Stale load / account switch | Load ids + account counter. Cleared on sign-out [tested] | App |
| Cron vs. check-out | Row lock; `close_due` re-checks `actual_checkout IS NULL` | **Database** |

---

## 6. Limitations of the existing database

1. **No check-out after the shift end.**
   - The existing `check_out` saves nothing at or after `scheduled_end` (or on an auto-closed day), yet returns the record id.
   - The app therefore never offers or sends a check-out then, and never reports such a call as success.
   - **Real after-4 PM checkout times and evidence can't be stored.** Employees are told to send an overtime request (the existing `request_overtime` workflow). Nothing is auto-approved.
2. **Near 16:00:** if the phone's clock is behind the server's, a check-out sent just before 16:00 can arrive after it. The app detects this on read-back and shows *closed automatically*. The selfie uploaded for that attempt stays orphaned.
3. **Orphaned selfies:** any failure after the upload leaves the object, because the bucket forbids DELETE. There are 3 such objects today.
4. **The work date uses the device clock** (in Cairo time). No exposed function returns the server's time. The database is still authoritative: `check_in` rejects the wrong date or shift, and the app reloads.
5. **Today's read is two requests**, not one snapshot. A change between them is caught by the unique constraint and the next reload.
6. **Lateness** is the database's `late_minutes = max(0, minutes late − grace)`. Shown as is; the rule should be confirmed.
7. **Error matching** for `P0001` relies on message text in the existing functions. It's covered by tests.

---

## 7. Tests actually run

| Command | Result |
|---|---|
| `flutter pub add timezone` / `pub get` | OK |
| `dart format lib test` | Done (see the formatter note in §3) |
| `flutter analyze` | **0 errors.** 2 warnings + 3 infos, all in files I didn't change |
| `flutter test` | **123 passed, 0 failed** |

The attendance tests use a fake that behaves like the real tables and functions, **including `check_out`'s silent no-op after the shift end**.

**Not run:**
- Tests against the real database. The only one is production, and writing test data is not authorized.
- On-device camera, GPS and permission runs. No device or emulator was available.

---

## 8. Not implemented (needs a database change)

| Requirement | Why not | What would be needed |
|---|---|---|
| Record a real check-out after 16:00 (time + evidence) | `check_out` discards it | A change to `check_out` |
| Server time / work date without the device clock | No read-only function exposes it | A read-only function |
| Clean up orphaned selfies | No DELETE policy | A server-side cleanup job |
