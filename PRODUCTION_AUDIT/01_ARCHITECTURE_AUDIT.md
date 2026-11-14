# 01 — Architecture audit (2026-11-12)

Evidence labels: **[run]** executed here · **[read]** inspected · **[not done]** could not be done.

## Environment
- Flutter 3.47.6 / Dart 3.13.5, Windows host. **No phone or emulator attached** (only Windows desktop, Chrome, Edge). [run]
- One backend: Supabase project `fotxyzooanysjthovpfz` ("employee-attendance"). It is the **production** database; there is no staging project. All database work in this audit was read-only. [read]
- Branch `hazem_branch`, HEAD `f98f222`. Uncommitted before the audit: a teammate's 6 notification/l10n files (left untouched).

## App
- 263 Dart files in `lib/`, 30 test files plus helpers (389 tests).
- Structure: `lib/app/features/<feature>/{domain,data,presentation}`, `lib/core/{services,router,errors,theme,widgets,manager}`.
- State: flutter_bloc Cubits with sealed states. DI: get_it (`core/services/getit_services.dart`). Routing: go_router with one guard (`AppRouter.redirectFor`) driven by the session and the permission set. Localization: gen-l10n, Arabic (default) + English.
- Features: auth, attendance_session (check-in/out flow), history, home, attendance_correction, cash_request, admin (dashboard, employees, requests, audit, edit), assigned_reviews, permissions, hr_reports (Excel export), notifications (inbox + Android push), profile, splash. `settings` routes are still placeholders.

| Flow | Path |
|---|---|
| Sign-in | `SupabaseAuthService` → `get_account_status` RPC → `AuthCubit` → router guard |
| Check-in / out | flow cubits → `SupabaseAttendanceRepository` → Storage upload → `check_in` / `check_out` RPC → read-back |
| Requests | `request_expense_advance`, `request_attendance_correction` RPCs; reads through RLS |
| Review | admin: `review_request`; delegated employee: `review_assigned_*` |
| Admin | RLS reads + `admin_*` RPCs + `employee-accounts` Edge Function (account creation, password) |
| Push | `register_push_device` RPC → triggers → `send-notification-push` Edge Function (cron, every minute) → FCM |

## Backend (live)
- 13 tables (10 `public`, 3 `private`), all with RLS; clients have SELECT only. 57 functions; every write goes through a SECURITY DEFINER function. 2 Edge Functions. 2 cron jobs (attendance auto-close; push sender). 1 private Storage bucket.
- Roles: `admin`, `employee` (text + CHECK). Per-employee reviewer flags (`can_review_*`) + per-request assignment.
- **No migration history in the database** (`list_migrations` is empty): the schema is changed by hand in the SQL editor. The repo's `supabase/migrations` and `supabase/ops` are copies, not a source of truth. See 03.

## Findings
| ID | Sev | Finding | Status |
|---|---|---|---|
| A-1 | **P0** | `lib/main.dart` did not compile at HEAD (bad merge: the router was created twice, once without the permission guard; a duplicated named argument). No test imported `main.dart`, so 388 tests passed while the app could not be built | **Fixed** + guard test `test/app_compiles_test.dart` + CI workflow |
| A-2 | P2 | No CI ran analyze/tests (only a Codemagic iOS simulator debug build) | **Fixed**: `.github/workflows/ci.yml` (analyze, test, release APK). Takes effect when pushed |
| A-3 | P3 | `cupertino_icons` is declared but unused; `supabase` is imported only by one test and belongs in `dev_dependencies` | Open — no effect on the build (tree-shaken) |
| A-4 | P3 | Two test seams bypass DI (`InboxRepository(Supabase.instance.client)` built in `main.dart`) | Left: working code, a teammate's feature |
| A-5 | P3 | `settings`, `language`, `privacy` routes are placeholders (language is switched on the Profile page) | Open |
| A-6 | P2 | Schema managed by hand, no staging database | Open — owner decision |
