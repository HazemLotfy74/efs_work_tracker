# Supabase Read-Only Audit — Authentication Readiness

- **Project:** `employee-attendance` (`fotxyzooanysjthovpfz`), eu-west-1, Postgres 17, status ACTIVE_HEALTHY
- **Date:** 2026-10-27
- **Method:** Supabase MCP. I only ran `SELECT`s on the catalogs, `list_tables`, `get_advisors`, `list_edge_functions` and `get_edge_function`. Nothing was inserted, updated, deleted or altered.
- **Privacy:** this report contains no emails, names, passwords, tokens or keys. User data appears only as counts.

---

## 0. Coverage — what was and was not inspected

| Area | Inspected | Notes |
|---|---|---|
| `public` tables, columns, PKs, FKs, uniques, checks, indexes | ✅ | 9 tables |
| Views / materialized views in app schemas | ✅ | **None exist** in `public` or `private` |
| Enums / domains | ✅ | **None exist**. Roles and statuses are `text` columns with `CHECK` constraints |
| Functions (`public`, `private`): definitions + EXECUTE grants | ✅ | 30 functions |
| Triggers (`public`, `auth`, `storage`) | ✅ | |
| RLS flags + every policy (USING / WITH CHECK) | ✅ | `public` and `storage.objects` |
| Table / column grants for `anon`, `authenticated`, `service_role` | ✅ | |
| Storage buckets + policies | ✅ | 1 bucket |
| `auth.users` structure link + metadata **key names** + aggregate counts | ✅ | No values read |
| Edge Functions (source) | ✅ | `employee-accounts` |
| pg_cron jobs | ✅ | 1 job |
| Security advisors | ✅ | 2 lint types |
| **Auth dashboard settings**: whether the Custom Access Token Hook is *enabled*, whether sign-ups are enabled, redirect URLs, email templates, SMTP, JWT expiry | ❌ **Not accessible** | The MCP has no Auth-config tool, and SQL can't see these settings. To check them, open **Dashboard → Authentication → Hooks / Sign In / Providers / URL Configuration**, or give me Management API access (`GET /v1/projects/{ref}/config/auth`) |
| Edge Function secrets (`ALLOWED_WEB_ORIGIN`, `PASSWORD_RESET_REDIRECT_URL`) | ❌ Not accessible | I can only confirm they are *referenced* in the code |

---

## 1. Schemas

| Schema | Purpose | Anon USAGE | Authenticated USAGE |
|---|---|---|---|
| `public` | App tables + client-callable RPCs | yes | yes |
| `private` | Helper / trigger / authorization functions (no tables) | **no** | yes (but only `is_active()` and `is_admin()` are executable) |
| `auth`, `storage`, `realtime`, `vault`, `cron`, `extensions`, `graphql*` | Supabase-managed | — | — |

---

## 2. Tables (`public`): all have RLS enabled

| Table | PK | Rows | Purpose |
|---|---|---|---|
| `profiles` | `id` | 2 | App profile, 1:1 with `auth.users` |
| `work_schedules` | `id` | 1 | Shift template (timezone, grace) |
| `schedule_days` | `(schedule_id, weekday)` | 5 | Per-weekday hours |
| `attendance_records` | `id` | 0 | One per employee per work_date |
| `attendance_events` | `id` | 0 | Check-in/out evidence (GPS + selfie path), append-only |
| `overtime_requests` | `id` | 0 | |
| `attendance_correction_requests` | `id` | 0 | |
| `expense_advance_requests` | `id` | 0 | Cash request |
| `audit_logs` | `id` (identity) | 4 | Append-only audit trail |

### 2.1 `public.profiles` (the profile table)

| Column | Type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | uuid | NO | — | PK; **FK → `auth.users(id)` ON DELETE RESTRICT** |
| `employee_code` | text | NO | — | UNIQUE; 2–50 chars (upper-cased by provisioning) |
| `username` | text | NO | — | UNIQUE; `^[a-z0-9][a-z0-9._-]{2,63}$` |
| `full_name` | text | NO | — | 1–200 chars |
| `role` | text | NO | `'employee'` | `CHECK role IN ('employee','admin')` |
| `is_active` | boolean | NO | `true` | |
| `must_change_password` | boolean | NO | `true` | |
| `schedule_id` | uuid | NO | — | FK → `work_schedules(id)` |
| `created_by` | uuid | YES | — | FK → `profiles(id)`; NULL = bootstrap admin |
| `provisioning_request_id` | uuid | YES | — | UNIQUE (idempotency key) |
| `created_at` / `updated_at` | timestamptz | NO | `now()` | `updated_at` maintained by trigger |

### 2.2 Other tables (summary)

- **`work_schedules`**: `id`, `name` (1–120), `timezone` (default `Africa/Cairo`, validated by trigger), `grace_minutes` (0–120, default 15), timestamps.
- **`schedule_days`**: `schedule_id` FK, `weekday` 0–6, `starts_at` (08:00), `ends_at` (16:00).
- **`attendance_records`**: `employee_id` FK→profiles, `work_date`, `schedule_id` FK, `timezone`, `scheduled_start/end`, `grace_minutes`, `actual_checkin/checkout`, `auto_closed(_at)`, `auto_close_processed_at`, `effective_checkin/checkout`, `has_correction`, `late_minutes` (GENERATED), timestamps. UNIQUE(`employee_id`,`work_date`).
- **`attendance_events`**: `attendance_id` FK, `event_type` ∈ {`check_in`,`check_out`}, `occurred_at`, `latitude`/`longitude`/`accuracy_m` (range-checked), `selfie_path` (UNIQUE). UNIQUE(`attendance_id`,`event_type`). UPDATE/DELETE are rejected by trigger.
- **`overtime_requests`**: `employee_id`, `work_date`, `period` ∈ {`before_4pm`,`after_4pm`}, `hours` > 0, `reason`, `status` ∈ {`pending`,`approved`,`rejected`}, `reviewed_by` FK→profiles, `reviewed_at`, `review_note`. Partial unique index: one non-rejected request per (employee, date, period).
- **`attendance_correction_requests`**: `employee_id`, `attendance_id` FK, `proposed_checkin/checkout`, `base_updated_at`, `reason`, status/review columns. Partial unique index: one pending request per attendance.
- **`expense_advance_requests`**: `employee_id`, `requested_amount` > 0, `currency` (`^[A-Z]{3}$`, default `EGP`), `reason`, status/review columns.
- **`audit_logs`**: `actor_id`, `actor_kind` ∈ {`user`,`system`,`database`}, `action`, `table_name`, `row_key`, `old_data`, `new_data`, `happened_at`, `transaction_id`. UPDATE/DELETE are rejected by trigger.

All FKs use `ON DELETE RESTRICT`. Every FK column has an index.

### 2.3 Relationship map

```
auth.users (1) ──── (1) profiles ──┬── (N) attendance_records ──┬── (≤2) attendance_events
                        │  │       │                            └── (N) attendance_correction_requests
                        │  │       ├── (N) overtime_requests        (reviewed_by → profiles)
                        │  │       └── (N) expense_advance_requests (reviewed_by → profiles)
                        │  └─ schedule_id → work_schedules (1) ── (N) schedule_days
                        └─ created_by → profiles (self-reference: the admin who created the account)
```

---

## 3. Authentication system (verified)

**Provider:** Supabase Auth, **email + password only**.

**How accounts are created:** there is no self sign-up.
1. An admin calls the Edge Function **`employee-accounts`** with `action: "create_employee"` and their own access token.
2. The function verifies the caller against `/auth/v1/user` and runs `backend_validate_employee`, which requires an active admin whose password is already changed. It then calls the Auth Admin API `createUser` with `email_confirm: true`. The employee details go into **`app_metadata.attendance_account`**.
3. The trigger **`auth.users AFTER INSERT → private.on_auth_user_created()`** reads only `raw_app_meta_data` (it never trusts `user_metadata`). It validates the data, checks that the email matches, and inserts the `profiles` row with `role='employee'`, `is_active=true` and `must_change_password=true`.
4. If `attendance_account` is missing, the trigger **raises an error**, so any plain `auth.signUp()` fails. The first admin was created through a one-time `bootstrap` path, which is now closed because an admin exists.

**Login gate:** `public.attendance_access_token_hook(event)` is a Custom Access Token Hook. It is executable by `supabase_auth_admin`. ⚠️ **I could not verify that the hook is enabled in the Auth settings.** If it is enabled:
- No profile, or `is_active = false` → the token is refused (HTTP 403, `"Account unavailable"`). This also applies to **token refresh**, so a deactivated user is cut off at their next refresh.
- `authentication_method` must be `password`, `token_refresh` or `recovery`. Anything else is refused with `"Email/password login required"`. Magic link, OTP and OAuth will not work.
- On `recovery` (password-reset link), it sets `must_change_password = true`.
- It adds **no custom claims**. The role is **not** in the JWT.

**Password change:** this must go through the Edge Function `employee-accounts` with `action: "change_password"` (`password`, optional `current_password` / `nonce`). The function updates the Auth password and then runs `backend_complete_password_change`, which sets `must_change_password = false`. **Calling `supabase.auth.updateUser(password:)` directly from Flutter would leave `must_change_password = true` and lock the user out of every feature.** Server-side rule: 12 characters minimum, 72 UTF-8 bytes maximum.

**Password reset:**
- *Admin-initiated:* the Edge Function action `send_password_reset` with `employee_id`. Admin only. It uses a server-configured redirect.
- *Self-service:* the database has nothing that blocks `auth.resetPasswordForEmail()`, and the hook allows `recovery`. Whether the redirect/deep link is configured could not be verified (see §0).

### 3.1 Current Auth data (counts only)

| role | is_active | must_change_password | created_by NULL | count | email confirmed | has `auth.users.phone` |
|---|---|---|---|---|---|---|
| admin | true | false | yes (bootstrap) | 1 | 1 | 0 |
| employee | true | false | no | 1 | 1 | 0 |

- No orphan `auth.users` exist without a profile. Neither user is banned.
- `app_metadata` keys: `provider`, `providers`, `attendance_account{bootstrap, created_by, email, employee_code, full_name, request_id, schedule_id, username}`
- `user_metadata` keys: **only `email_verified`**. There is no `displayName`, `phone`, `role` or `avatar_url`.

---

## 4. Roles (actual, not guessed)

- **No roles table, no role IDs, no permissions table, no enum.**
- The role is the column `public.profiles.role` (text) with `CHECK (role IN ('employee','admin'))`. Default: `'employee'`.
- The **only two role values** are `employee` and `admin`. Both are in use (1 each).
- How permissions are enforced:
  - `private.is_active()`: profile exists, `is_active = true` and `must_change_password = false`.
  - `private.is_admin()`: same as `is_active()`, plus `role = 'admin'`.
  - `private.require_actor(p_admin)`: raises `42501` unless the caller is active with password changed (and is an admin when `p_admin = true`).
  - `private.require_backend_admin(p_actor)`: the same check, used by Edge/service RPCs.
- Admins cannot deactivate other admins or themselves (`admin_set_employee_active` targets only `role='employee'`).

---

## 5. Where each user attribute lives

| Attribute | Location | Readable by the Flutter client? |
|---|---|---|
| User ID | `auth.users.id` = `profiles.id` | yes (`currentUser.id`) |
| Email | **`auth.users.email` only** (no email column in `profiles`) | own email via `currentUser.email` |
| Full name | `profiles.full_name` | yes, via RPC / own row (see §7) |
| Username | `profiles.username` | yes |
| Employee code | `profiles.employee_code` | yes |
| Role | `profiles.role` | yes. **Never read it from `user_metadata`** |
| Account status | `profiles.is_active`, `profiles.must_change_password` (+ `auth.users.banned_until`, unused) | yes |
| Schedule | `profiles.schedule_id` → `work_schedules`, `schedule_days` | yes, only once the user is active |
| **Phone** | **Does not exist.** `auth.users.phone` is empty for every user. `private.normalize_phone()` exists but nothing calls it. There is no phone column | — |
| **Profile image** | **Does not exist.** There is no avatar column and no avatar bucket | — |

---

## 6. RLS policies (all verified)

All 9 `public` tables have **RLS enabled** (`FORCE` off, which is the normal setting). Every policy is `PERMISSIVE`, `SELECT` only, and applies to role `authenticated`. **There are no INSERT/UPDATE/DELETE policies, and `authenticated` has only `SELECT` grants.** All writes go through `SECURITY DEFINER` RPCs. **`anon` has no grants on any `public` table.**

| Table | Policy | USING |
|---|---|---|
| `profiles` | `profile_read` | `is_active() AND (id = auth.uid() OR is_admin())` |
| `attendance_records` | `attendance_read` | `is_active() AND (employee_id = auth.uid() OR is_admin())` |
| `attendance_events` | `event_read` | `is_active() AND EXISTS(record where record.id = attendance_id AND (record.employee_id = auth.uid() OR is_admin()))` |
| `overtime_requests` | `overtime_read` | `is_active() AND (employee_id = auth.uid() OR is_admin())` |
| `attendance_correction_requests` | `correction_read` | same pattern |
| `expense_advance_requests` | `advance_read` | same pattern |
| `work_schedules` | `work_schedules_read_ready_users` | `is_active()` |
| `schedule_days` | `schedule_days_read_ready_users` | `is_active()` |
| `audit_logs` | `audit_read` | `is_admin()` |

`service_role` has full grants on `work_schedules` and `schedule_days` only (plus its usual RLS bypass).

### 6.1 RPCs the client may call (`authenticated` EXECUTE; `anon` has none)

| RPC | Guard | Use |
|---|---|---|
| `get_account_status()` | `auth.uid()` must have a profile | **Profile + status loader** |
| `check_in(lat, lng, accuracy_m, selfie_path)` | `require_actor(false)` + `assert_selfie` | |
| `check_out(attendance_id, lat, lng, accuracy_m, selfie_path)` | `require_actor(false)` + `assert_selfie` | |
| `request_overtime(work_date, period, hours, reason)` | `require_actor(false)` | |
| `request_attendance_correction(attendance_id, checkin, checkout, reason)` | `require_actor(false)` | |
| `request_expense_advance(amount, reason, currency)` | `require_actor(false)` | |
| `review_request(kind, request_id, approve, note)` | `require_actor(true)` | admin |
| `admin_assign_schedule`, `admin_set_employee_active`, `admin_set_grace` | `require_actor(true)` | admin |

`backend_*` functions are `service_role` only (used by the Edge Function). `attendance_access_token_hook` is `supabase_auth_admin` only.

### 6.2 Storage

- **Bucket `attendance-evidence`**: private, 5 MB limit, `image/jpeg|png|webp`, 3 objects.
- **Upload (INSERT, authenticated):** bucket matches, `is_active()`, `owner_id = auth.uid()`, and the path matches `^<uid>/<uuid-v4-like>.(jpg|jpeg|png|webp)$`.
- **Read (SELECT, authenticated):** `is_active()` and either (own folder and owner) or (admin and the path is referenced by an `attendance_events.selfie_path`).
- **UPDATE / DELETE (anon + authenticated):** policies with `USING (bucket_id <> 'attendance-evidence')`. See finding **S-1**.
- **No profile-image bucket exists.**

### 6.3 Background jobs and triggers relevant to auth

- `cron: attendance-auto-close` runs every minute → `private.auto_close_attendance()`.
- `profiles` triggers: `touch_updated_at` (BEFORE UPDATE), `audit_change` (AFTER UPDATE/DELETE). Profile INSERT is audited inside `on_auth_user_created`.

---

## 7. How an authenticated user is supposed to load their own profile

1. `signInWithPassword(email, password)`. If the hook is on, this fails with 403 for inactive or missing profiles.
2. **Call `rpc('get_account_status')`**. It returns `{id, full_name, username, employee_code, role, is_active, must_change_password}`. This is the **only** path that works when `must_change_password = true`.
3. If `must_change_password == true` → send the user to a change-password screen → `functions.invoke('employee-accounts', body: {action: 'change_password', password, current_password?})` → call `get_account_status` again.
4. If `is_active == false` (for example, deactivated during a session) → sign out.
5. Only when `is_active && !must_change_password` can the user read `profiles` directly (`select().eq('id', uid).single()`, which adds `schedule_id`, `created_at`), use any table, or call any feature RPC.

> ⚠️ A direct `from('profiles').select().eq('id', uid)` for a user with `must_change_password = true` returns **0 rows, not an error**, because `profile_read` requires `is_active()`. Code that uses `.single()` will throw "no rows". This is the most likely profile-loading bug.

---

## 8. Findings

### Security / database

| ID | Severity | Finding |
|---|---|---|
| **S-1** | Medium (latent) | The storage policies `attendance_selfie_no_delete` / `attendance_selfie_no_update` are **PERMISSIVE** with `bucket_id <> 'attendance-evidence'`. Permissive policies *grant* access. Today this lets **`anon` and `authenticated` delete or update objects in every other bucket**. Only one bucket exists, so nothing is exposed right now, but the first new bucket (for example, avatars) would be writable and deletable by anyone. Making them `AS RESTRICTIVE`, or dropping them (no DELETE/UPDATE policy already means deny), fixes it. *Not changed: audit is read-only.* |
| S-2 | Low (advisor WARN) | **Leaked password protection is disabled** (Auth). [Remediation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) |
| S-3 | Info (advisor WARN, ×10) | `SECURITY DEFINER` RPCs are executable by `authenticated`. **This is intentional.** I verified that each one calls `require_actor` (or uses `auth.uid()`) and has `search_path=''`. No action needed. [Lint 0029](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) |
| S-4 | Unverified | The Custom Access Token Hook *function* exists, but I can't confirm that it is **enabled**. If it is off: inactive users can still log in and refresh (RLS still blocks their data), and recovery logins don't force a password change. |
| S-5 | Unverified | Whether public sign-ups are enabled. Even if they are, the trigger makes `signUp` fail with a generic "Database error saving new user". Recommend disabling sign-ups in the dashboard. |
| S-6 | Info | Edge Function `employee-accounts` has `verify_jwt = false` but **verifies tokens itself** via `/auth/v1/user`. CORS is allowed only for `ALLOWED_WEB_ORIGIN`. Mobile requests (no Origin header) pass. OK. |
| S-7 | Info | `admin_set_employee_active(false)` does not revoke sessions. The current access token stays valid until it expires, but every RLS policy and RPC re-checks `is_active`, and refresh is blocked by the hook (if enabled). The app must treat a `42501` as "sign out". |
| ✅ | — | No service-role key, secret key or JWT is in the Flutter source. The publishable key in `constants.dart` is designed to be public. |

### Flutter vs. database mismatches

| ID | File | Issue |
|---|---|---|
| F-1 | `lib/app/features/auth/data/models/user_model.dart` | **Doesn't compile**: `OAuthUser` (wrong type, should be `User`), `user?['displayName']`, and `fromUserEntity` / `fromMap` omit required params. Reads `role`, `phone`, `avatar_url` and `displayName` from `userMetadata`. **None of these exist there** (only `email_verified`). Reading the **role from `user_metadata` is also unsafe** because users can edit it. Imports `package:supabase` instead of `supabase_flutter`. |
| F-2 | `lib/app/features/auth/domain/entities/user_entity.dart` | Has `phone` and `image`, which have **no backing column**. Missing the fields that do exist: `username`, `employeeCode`, `isActive`, `mustChangePassword` (and optionally `scheduleId`). `role` should be limited to `employee` / `admin`. |
| F-3 | `lib/core/services/supabase_auth_service.dart` | Only `signInWithPassword`. Missing: sign-out, current session, auth-state stream, profile load via `get_account_status`, change-password via the Edge Function, and the reset request. Log text says "firebase". Returns `Future.error(AuthFailure)`, while the rest of `core/errors` uses `CustomExceptions`. Imports `package:supabase`. |
| F-4 | `lib/core/errors/failure.dart` | `AuthFailure.fromSupabaseError` maps `user_already_registered` (sign-up isn't possible) but not the cases that actually happen: hook 403 "Account unavailable" / "Email/password login required", `email_not_confirmed`, `over_request_rate_limit`, `same_password`, PostgREST `42501` (not active or password not changed) and `P0001`. Edge Function codes: `forbidden`, `invalid_input`, `password_completion_pending`, `unauthorized`. Verify the exact hook-rejection code at runtime. |
| F-5 | `lib/core/functions/form_validator_functions.dart` | Password minimum is 6. The server requires **≥ 12 characters and ≤ 72 UTF-8 bytes** for new passwords. Login can stay lenient; change-password must use 12. |
| F-6 | `lib/core/services/database_services.dart` | The interface has no `rpc` method. Profile loading and every write in this database go through RPCs. |
| F-7 | `lib/core/services/getit_services.dart` | `setup()` is empty and is never called from `main.dart`. |
| F-8 | `lib/app/features/auth/presentation/widgets/login_view_form_field.dart` | Fields have no controllers. The sign-in button just `push`es `/home` with no auth call. "Remember me" has no effect: `supabase_flutter` persists sessions by default. |
| F-9 | `lib/app/features/auth/presentation/widgets/forgot_password_view_body.dart` | TODO. No reset call, and no deep-link handling for the recovery redirect. |
| F-10 | `lib/app/features/splash/presentation/views/splash_view.dart` / `lib/core/router/app_router.dart` | The splash always `go`es to `/home`. The router has no auth `redirect`/`refreshListenable`, so every route is reachable without a session. |
| F-11 | `lib/core/router/app_routes.dart` | **There is no change-password route or screen**, but the database requires one before any feature works (every new account has `must_change_password = true`). Check whether the Figma design has a screen for this. |
| F-12 | `lib/app/features/home/presentation/widgets/user_header.dart` | Name and initials are hard-coded (`"Mohamed"`, `"MH"`). They should come from `full_name`. |
| F-13 | `pubspec.yaml` | Both `supabase` and `supabase_flutter` are direct dependencies. `supabase_flutter` already re-exports `supabase`. Keeping both risks version skew. |

---

## 9. Flutter files that must be integrated with Authentication

**Existing, must change**
1. `lib/app/features/auth/domain/entities/user_entity.dart`: align its fields with §5
2. `lib/app/features/auth/data/models/user_model.dart`: `fromAccountStatus(Map)` (RPC result) + email from `auth.currentUser`
3. `lib/core/services/supabase_auth_service.dart`: sign-in, sign-out, session/stream, reset, change-password (Edge Function)
4. `lib/core/services/database_services.dart`: add an `rpc` capability (plus a Supabase implementation)
5. `lib/core/services/getit_services.dart`: register the services and repository; call `setup()` in `main.dart`
6. `lib/core/errors/failure.dart` and `lib/core/errors/exceptions.dart`: real error mapping (F-4)
7. `lib/core/constants/constants.dart`: no change to its values. Optionally add the Edge Function name `employee-accounts`
8. `lib/main.dart`: call `setup()`; provide the auth cubit above the router
9. `lib/core/router/app_router.dart` and `lib/core/router/app_routes.dart`: auth redirect, plus a change-password route
10. `lib/app/features/splash/presentation/views/splash_view.dart`: route from the session/status
11. `lib/app/features/auth/presentation/widgets/login_view_form_field.dart`: controllers + cubit
12. `lib/app/features/auth/presentation/widgets/forgot_password_view_body.dart`: reset request
13. `lib/core/functions/form_validator_functions.dart`: a 12-char validator for new passwords
14. `lib/app/features/home/presentation/widgets/user_header.dart`: show the profile name/initials
15. `pubspec.yaml`: drop the direct `supabase` dependency (optional)

**New, following the existing `attendance_session` layering** (`domain/repositories`, `data/repositories`, `presentation/manager/<name>_cubit/`)
- `lib/app/features/auth/domain/repositories/auth_repository.dart`
- `lib/app/features/auth/data/repositories/supabase_auth_repository.dart`
- `lib/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart` + `auth_state.dart`
- A change-password view/widget under `lib/app/features/auth/presentation/` (design to be confirmed)

**Later, not part of Authentication:** `in_memory_attendance_repository.dart` → Supabase. The selfie upload path must be `<auth.uid()>/<uuid>.<ext>` in `attendance-evidence`.

---

## 10. Open items needing your input / dashboard access

1. Is the **Custom Access Token Hook enabled** (Auth → Hooks → `public.attendance_access_token_hook`)?
2. Are **public sign-ups disabled**?
3. What is the **password-reset redirect URL** / mobile deep-link scheme (Auth → URL Configuration, and the Edge secret `PASSWORD_RESET_REDIRECT_URL`)?
4. Is there a **change-password screen in Figma**?
5. Do you want **phone** or **profile image**? Neither exists in the database today. Adding them would be a schema change. I won't invent them.
