# Attendance History: Supabase verification

Verified 2026-11-01 against project `employee-attendance` (`fotxyzooanysjthovpfz`).

## Application wiring

The History tab uses `AttendanceHistoryCubit` → `HistoryRepository` →
`SupabaseHistoryRepository` → `SupabaseDatabaseServices`. The production
dependency registration selects the Supabase repository, not an in-memory source.
The UI has no demo-data fallback.

History owns its data layer under `lib/app/features/history/data/`:
`models/attendance_history_model.dart` maps rows to the existing shared attendance
entity, and `repositories/supabase_history_repository.dart` owns monthly queries
and read-error handling. The Cubit depends on the interface in
`domain/repositories/history_repository.dart`. Existing attendance model mapping
is reused to keep timezone, event and correction rules consistent.

The query reads `attendance_records` with embedded `attendance_events`, explicitly
filters `employee_id` to the signed-in user, applies inclusive/exclusive work-date
bounds for the selected month, orders newest first and limits to 60. The database
enforces one row per employee/work date, so this covers a complete month.

The configured API URL matches the connected project. The configured publishable
key is listed by Supabase and is enabled. No secret/service-role key was needed.

## Live checks

- All selected record/event fields exist, including `auto_close_deadline`,
  `auto_close_policy`, effective timestamps and nullable checkout fields.
- The `attendance_events.attendance_id` foreign key supports the nested query.
- RLS is enabled on profiles, records and events. Authenticated clients have
  SELECT grants; anonymous clients have no table SELECT grant.
- Policies require an active profile whose first-login password change is complete.
  Employees read their own rows; administrators may read all rows. The personal
  History screen deliberately applies its own employee filter even for admins.
- The `(employee_id, work_date)` unique index supports the monthly query.
- Existing data: three attendance records across three accounts, all in November
  2026; October 2026 has no records at the time of verification.
- A live HTTPS request with the app's publishable key and no user session returned
  HTTP 401 for attendance reads, confirming anonymous access is denied.

### SQL role simulations

These checks ran inside explicit read-only transactions using `SET LOCAL ROLE
authenticated` and transaction-local JWT claims, followed by rollback. They tested
deployed policies, not authenticated phone sessions or signed JWT issuance.

| Scenario | Visible records | Other employees' records | Own November records | Own October records |
| --- | --- | --- | --- | --- |
| Employee 1 | 1 | 0 | 1 | 0 |
| Employee 2 | 1 | 0 | 1 | 0 |
| Administrator | 3 | 2 | 1 | 0 |
| Authenticated subject without a profile | 0 | 0 | — | — |

The two employee contexts could see only their associated evidence rows (two and
one events respectively); the administrator could see all four events.

No database schema, policy, account or business record was changed. Detailed
employee records were not exported: automatic review rejected that proposed query
because its payload included personal attendance data. Verification used catalog
metadata, aggregate counts and role simulations instead.

## SDK verification

`SupabaseDatabaseServices` accepts an optional client so tests can exercise the real
Supabase/PostgREST query builder with an HTTP mock. Production still defaults to
`Supabase.instance.client`.

`test/attendance_history_transport_test.dart` checks the generated HTTP request:
owner filtering, both month boundaries, ordering, selected nested events and limit.
Synthetic responses matching the inspected schema verify timestamps, Cairo shift
conversion, durations, evidence mapping, empty months, unconfirmed auto-closed days
and permission-error handling. These responses contain no production personal data.

A screen-level test also taps History in the actual MainLayoutView navigation,
loads the real HistoryView with SupabaseHistoryRepository, and verifies that
the returned record, count and duration appear on screen. Its database service and
authentication are fakes; the separate transport tests exercise the Supabase SDK.

## Remaining verification boundary

Validation: the full Flutter suite passed (248 tests), including four SDK
transport contract tests. Static analysis reported only the three pre-existing
deprecation notices in generated assets code.

A real sign-in and on-device History screen run were not performed. Log in normally,
open History and select November 2026 to view the signed-in account's saved records.
The current production schema and access policies need no change for this feature.

## Separate existing advisories

Supabase reports authenticated-callable SECURITY DEFINER RPC warnings and disabled
leaked-password protection. The History screen itself uses SELECT, not those write
RPCs. No policies or RPC permissions were changed as part of this verification.

- RPC advisory: https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- Password protection: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Performance advisors reported unused indexes; no index removal is justified by this
small dataset. The current changelog was checked; no relevant query API migration
was identified for this integration. Old-device TLS cipher removal is scheduled
for November 10 or later: https://supabase.com/changelog/cbc-tls-ciphers-deprecated
