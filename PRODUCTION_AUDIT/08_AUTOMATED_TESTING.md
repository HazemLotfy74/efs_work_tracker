# 08 — Automated testing (2026-11-12)

## Commands actually run, and results
| Command | Result |
|---|---|
| `flutter pub get` | OK |
| `flutter analyze` (before fixes) | **2 errors** in `lib/main.dart`, 4 infos |
| `flutter analyze` (after fixes) | 0 errors, 0 warnings, 6 infos at the final run (3 in generated code, 3 style notes in `auth_cubit.dart`, `phone_alerts.dart`, `inbox_cubit.dart`) |
| `flutter test` (before fixes) | 388 passed — while the app did not compile (no test imported `main.dart`) |
| `flutter test` (after fixes) | **389 passed, 0 failed** |
| `flutter build apk --release --split-per-abi` | Built (3 ABIs) |
| `flutter build appbundle --release` | Built |
| `node --test supabase/tests/send_notification_push.test.mjs` | 1 passed |
| `node --test supabase/tests/notification_push.test.mjs` | **Blocked**: needs `@electric-sql/pglite`; the repo has no `package.json` to install it from |
| `flutter pub outdated` | Nothing discontinued or retracted |

## What the 389 tests are
Unit tests (duration rules, models, error mapping, validators), cubit tests (auth, attendance,
history, corrections, cash, admin, permissions, assigned reviews, inbox), repository tests against
fake database/storage that mirror the live functions' behaviour, and widget tests (screens at
several sizes, languages, text scales and themes). See 02 for the coverage table.

## What is **not** covered by any automated test
| Gap | Why |
|---|---|
| The real database: RLS as each role, function behaviour, concurrency | Production is the only database; no test project |
| The real Supabase Auth: sign-in, token refresh, suspension, reset link, email change | Same |
| Camera, GPS, permissions dialogs, push delivery | Need a device |
| Integration tests (`integration_test/`) | None exist |
| Edge Functions | One Deno/Node test runs; the other is blocked |

## Added in this audit
- `test/app_compiles_test.dart` — fails `flutter test` if `lib/main.dart` stops compiling.
- `.github/workflows/ci.yml` — analyze, test and a release APK build on every pull request.

## Recommended next (in order of value)
1. A second Supabase project for tests, loaded from the SQL files, so RLS and the attendance functions can be tested as each role and under concurrency.
2. One `integration_test` that drives sign-in → check-in → check-out on an emulator against that project.
3. A `package.json` in `supabase/tests` so the push tests run in CI.
