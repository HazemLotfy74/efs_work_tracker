# Project and security review

Reviewed 2026-10-31. Checkout: `1fb1353`. Application source was not changed.

## Scope and confidence

Reviewed the repository layout, Flutter entry point and dependency injection, routes, authentication, data repositories, attendance and request state flows, evidence upload, location and camera handling, platform configuration, localization, tests, and existing audit reports. Inventoried 314 tracked files, including 214 files under lib and 21 under test. Fonts and PNGs were inventoried rather than audited as source code.

Scanned source/configuration text in the working tree (excluding Git internals, IDE files and generated tool caches) and every commit reachable with `git rev-list --all`: 15 commits across the locally available branches/tags. This checkout is not shallow. Searches covered Supabase publishable/secret keys, JWTs, private key headers, common GitHub/AWS/OpenAI/Google key formats, credential-bearing PostgreSQL URIs, and credential-related code. This is pattern-based detection, not a guarantee that no unusual or encoded secret exists. No secret values are reproduced here. No remote refs were fetched; inaccessible, deleted, unreachable, or remote-only history is outside scope.

The configured GitHub repository is publicly visible: https://github.com/HazemLotfy74/efs_work_tracker . Public visibility does not establish that every local revision has been pushed. Current source contains a publishable key and distributing this app exposes that key regardless of repository visibility.

There is no Supabase connector available in this session. No live database, bucket policies, function deployments, authentication settings or production data were tested. Existing documents dated October 27–29 describe previous live audits; their backend claims are historical evidence, not current verification. No penetration test, dependency advisory scan, Android/iOS build, or device run was performed.

## What the project does

Efs WorkTrack is a Flutter/Dart mobile employee attendance application for a single organization, with employee and administrator roles. Android and iOS platform projects are present. Some code supports web file handling, but a web runner is not included in this checkout.

Employee capabilities:

- Email/password login, persisted session restoration, logout, first-login password change and email recovery.
- Check-in/check-out through preparation, GPS location, front-camera selfie, review and confirmation steps.
- Today's shift, attendance status, lateness, elapsed work, regular time, overtime and early-leave shortfall.
- Attendance history (default most recent 60 records), day details and attendance correction requests.
- Cash/expense advance requests and status history (default most recent 200).
- Profile, account details, schedule and persisted Arabic/English switching.

Administrator capabilities:

- Employee directory/search and today's attendance board, with employee history.
- Employee provisioning through the employee-accounts Edge Function, without replacing the administrator's session.
- Approval/rejection of other employees' cash and attendance correction requests.

Overtime is calculated automatically from elapsed time beyond eight hours. Overtime request screens/repositories were removed; old backend tables/functions are documented as remaining. Notifications, settings, standalone language route and privacy route are placeholders. Language selection itself works from the profile. No payroll, breaks, departments or tenant isolation are implemented here. Backend documentation describes one company and globally scoped administrators.

## Architecture and data flow

`lib/main.dart` initializes Supabase, registers GetIt singletons, creates authentication/attendance Cubits and GoRouter, then provides repositories and shared Cubits above the router. Attendance reloads when the account changes and when the app resumes.

Features are organized under `lib/app/features/` into data models/repositories, domain entities/interfaces and presentation views/widgets/Cubits. Shared services, routing, errors, validators, time/locale handling and theme live under `lib/core/`. Localization source is `lib/l10n/app_en.arb` and `app_ar.arb`; generated localization and asset code also exist.

Main dependencies include flutter_bloc (state), go_router (navigation), get_it (dependency injection), supabase_flutter (auth/database/storage/functions), geolocator/geocoding (location), flutter_map/OpenStreetMap (maps), image_picker (camera), timezone (business timezone), http (reverse geocoding), and shared_preferences (locale and SDK session persistence). The declared Dart constraint is `^3.13.5`; version is `1.0.0+1`.

Authentication loads role/account readiness through `get_account_status`; roles are not taken from user-editable metadata. Router guards separate signed-out, password-change-required, employee and admin states. Business writes call RPCs rather than directly updating tables. Account creation and password changes call `employee-accounts` using the current user's access token.

Documented backend tables: profiles, work_schedules, schedule_days, attendance_records, attendance_events, attendance_correction_requests, expense_advance_requests, overtime_requests and audit_logs. Definitions/migrations and deployable Edge Function source are absent. Recreating or independently verifying the backend from this repository alone is therefore not possible.

Attendance sends coordinates, reported accuracy and an uploaded selfie path. It does not send a client timestamp as the official check-in/out time. Historical audits say RPCs use server time. Evidence paths use the current UID and cryptographically random UUID. Uploads do not request overwrite. Attendance retries reconcile against saved evidence paths instead of blindly creating another event. The shared attendance Cubit discards stale results after account switches.

Regular time is capped at eight hours; overtime is the excess and no breaks are deducted. Auto-closed days have no verified duration until an approved correction supplies times. Current models distinguish scheduled shift end from auto-close deadline, documented as midnight by default. Older audit sections describing checkout closure at 16:00 are superseded by later code/documents and must not be treated as current server verification.

## Are any keys exposed?

| Item | Finding | Meaning |
| --- | --- | --- |
| Supabase project URL | Hardcoded in lib/core/constants/constants.dart | Public project identifier, not a credential |
| Supabase publishable key | Hardcoded in the same file; found in two reachable commit snapshots | Intentionally client-visible; not a privileged secret |
| Supabase secret/service-role key or JWT | No matching value detected in scanned files/history | No detected privileged Supabase credential leak |
| Private key, GitHub/AWS/OpenAI/Google credentials, PostgreSQL password URI | No matching value detected | Bounded negative result, not proof of absence |
| Test passwords | Dummy strings in fake/unit tests | No evidence they are live credentials |
| Environment files or signing key files | No .env, PEM, KEY, JKS or keystore files found in the scoped working-tree inventory | Future accidental additions still need prevention |

Supabase explicitly permits publishable keys in mobile apps and source code. They identify the application; RLS, grants and server-side authorization determine what a caller can do. Moving this key to a Flutter .env or dart-define would separate configuration but would not make it secret in a distributed app. No rotation is indicated solely because this publishable key is present. A discovered secret/service-role key would require immediate revocation/rotation and history remediation.

Reference: https://supabase.com/docs/guides/getting-started/api-keys

## Findings and recommended fixes

### 1. High release priority: Android release uses debug signing (confirmed)

`android/app/build.gradle.kts`, release build type, explicitly uses `signingConfigs.getByName("debug")`. Production artifacts would use a development signing identity. Configure the appropriate production/upload signing setup, keep the keystore and passwords outside Git, and verify the produced artifact certificate. No private signing key was found in this repository.

### 2. High assurance gap: current backend authorization cannot be verified

This is not a confirmed exploit. Direct client access is secure only if deployed RLS, grants, storage rules and privileged functions are correct. SQL migrations and Edge Function source are absent, and there is no live connection here. Existing reports claim SELECT-only client grants, owner/admin read policies, guarded RPCs, private evidence storage and append-only auditing. Recheck these against deployment, including SECURITY DEFINER search paths/EXECUTE grants, actor ownership, self-review prevention, inactive accounts, first-login password gates, token hook activation, signup restrictions, rate limits and password recovery redirects. Keep backend definitions under version control without secrets so future audits can verify implementation.

### 3. Medium: mock, old or inaccurate GPS is accepted by the client (confirmed)

`LocationCubit` stores `Position.isMocked`, timestamp and accuracy. `AttendanceEventEntity.hasLocation` checks only non-null, and the attendance repository requires only a location object. No freshness, acceptable-accuracy or mocked-location rejection occurs in this path. `isMocked` and capture time are not included in the check-in/out RPC parameters. The UI nevertheless uses the localized label `Verified · {meters}m`.

An employee using a mock-location provider can therefore pass the app's location step; direct API callers can also supply coordinates. This does not establish a live backend geofence bypass: no geofence or device-attestation policy was verified. Define the desired attendance integrity policy, reject known mocked/stale/poor readings where appropriate, avoid overstating verification, and enforce applicable constraints server-side. Client flags alone cannot prove physical presence. Selfie capture likewise provides evidence rather than verified identity/liveness.

### 4. Medium: sessions use ordinary preference storage (confirmed default)

`main.dart` supplies no custom Supabase local storage. The installed supabase_flutter 2.18.3 implementation defaults to SharedPreferencesLocalStorage, persisting the session as a string. There is no app-configured Keychain/Keystore-backed encrypted session store. Device/app-data compromise can expose bearer and refresh tokens. This is a device-side hardening gap, not evidence of public access. Use an appropriate secure storage implementation and review platform backup behavior for session data and local photos.

### 5. Medium privacy gap: precise coordinates go to an external service (confirmed)

`lib/core/services/address_service.dart` falls back to Nominatim with latitude and longitude in HTTPS query parameters. `location_map.dart` requests external OpenStreetMap tiles, revealing the viewed area and network metadata. The privacy route is still a placeholder. Provide an accurate privacy explanation covering Supabase evidence storage and external location providers, define retention/access rules, and decide whether this fallback should be optional or replaced. The exact coordinates are sent by reverse geocoding, not by the tile URL itself.

### 6. Medium latent backend risk: historical permissive storage policies (not reverified)

`docs/full_app_audit.md` S-1 reports permissive update/delete policies with `bucket_id <> 'attendance-evidence'`. If still deployed alongside applicable grants, they can authorize changes in other buckets; the earlier audit described only one bucket then. Inspect current policies and replace with appropriately scoped policies/restrictive guards as needed. Do not conclude the current evidence bucket is public from this finding.

### 7. Release blocker: missing iOS camera permission description (confirmed)

`SelfiePageView` opens `ImageSource.camera`, but `ios/Runner/Info.plist` contains no `NSCameraUsageDescription`. The iOS attendance flow cannot be relied on to open the camera and may terminate when camera access is attempted. Add the required purpose description and test allow/deny behavior on a real device. This is a functional/privacy configuration defect, not a credential leak.

### 8. Low: secret-file prevention is incomplete (confirmed)

The root .gitignore does not explicitly ignore .env variants or private signing/certificate files. Some platform-generated secret files are covered by platform ignore rules; protection is not comprehensive. Add carefully scoped ignore rules, a sanitized configuration example where needed, and automated secret scanning in CI/pre-commit. Gitignore does not remove already committed secrets and should not be the only control.

## Additional reliability and maintenance concerns

- Cash request retry safety is heuristic: the singleton repository remembers previous matching rows in memory and matches amount/reason/currency. There is no server idempotency key in the request payload. App restart, delayed requests or concurrent identical submissions can still produce duplicate financial requests. Introduce a server-enforced unique request ID. This is a correctness concern, not a confirmed duplicate payment exploit.
- Evidence is uploaded before the attendance RPC. A subsequent failure can leave an orphan. Historical reports say deletes are forbidden. Establish server-side orphan cleanup and explicit evidence retention, preserving evidence used by saved records.
- SupabaseDatabaseServices.updateData/deleteData allow calls without a filter, and getStreamData ignores its query argument. They are latent hazards: the currently reviewed business writes use RPCs, and no current privilege bypass is established. Require filters for generic destructive helpers or remove unused helpers.
- Auth role/account state is loaded at startup/login/password change; the app does not continuously revalidate authorization state. Backend checks must enforce immediate deactivation/role changes. Revalidating on resume improves UI accuracy but cannot replace those checks.
- Most history/request reads use fixed limits, with no pagination. Admin profiles and today's attendance can be affected by backend row limits as the workforce grows. Add pagination/aggregation when needed.
- Admin dashboards refresh on opening/pull-to-refresh, not continuously. Ordinary attendance/history refresh failures may retain earlier data without the same explicit stale banner as the admin dashboard.
- README remains the Flutter starter text. There is no CI workflow in this checkout. Document supported SDK versions, setup, environments, backend deployment, signing, recovery configuration and release validation.
- Older audit reports contain superseded feature/status descriptions. Read their final amendments and compare to code; their test totals are historical.
- Some validators return English-only messages despite Arabic support. Generated legacy localization/asset outputs coexist with current gen-l10n and should be kept consistent.

## Validation performed in this review

| Check | Result |
| --- | --- |
| flutter test --no-pub --reporter compact | 234 passed, 0 failed |
| flutter analyze --no-pub | No errors/warnings; 3 info-level deprecations in generated assets.dart at lines 147, 148 and 150; command exit code 1 |
| Credential pattern scan | Publishable key only; no matching privileged credentials in scoped files/reachable history |
| Working-tree status before review | Clean |
| Production writes | None |
| Application source modifications | None; this report was added |

Tests use fake services/repositories and do not prove production RLS or deployed Edge Function authorization. Passing widget tests do not verify native camera/GPS permissions. Package versions were inventoried but not checked against an advisory database, so no dependency-vulnerability conclusion is made.

## Suggested order of work

1. Verify deployed authorization/storage/auth settings and bring backend definitions into the repository.
2. Configure production Android signing and iOS camera permission text.
3. Define location/selfie integrity requirements and resolve mocked/stale-location handling and misleading verification labels.
4. Harden token persistence, complete privacy information and define evidence retention/cleanup.
5. Add server idempotency for cash requests and automated secret/release checks.
6. Run end-to-end tests with separate employee/admin test accounts: ownership isolation, denied direct writes, inactive-account access, password recovery, provisioning, review restrictions and private evidence access. Use a staging environment for writes.

Assessment: the Flutter application has a clear feature-based architecture and a passing test suite. No privileged credential leak was detected. Production readiness remains unproven until backend access controls and native release flows are verified and the confirmed configuration/integrity issues are resolved.
