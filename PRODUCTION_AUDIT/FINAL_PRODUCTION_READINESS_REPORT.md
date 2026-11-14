# Final production readiness report — Efs WorkTrack (2026-11-12)

## Decision: **NOT READY FOR PRODUCTION**

The code and the database design are in good shape, but three things that only you can do are
still missing, and without them nobody has evidence that the shipped app works:

1. **No release signing key.** Every release build is signed with the debug key.
2. **The current release build has never been launched on a phone.** The committed code did not even compile until this audit fixed it, and this app has already had one release-only white screen.
3. **No end-to-end run with real accounts** (sign-in → check-in → check-out → correction → review), and the Auth dashboard settings are unverified.

None of these is a design problem. With the checklist in `09_RELEASE_READINESS.md` done and passing,
the status becomes *Ready with documented limitations*.

## 1. Executive summary
- **Health:** good architecture, strong server-side enforcement, 389 passing tests.
- **Critical finding:** `lib/main.dart` did not compile at the current commit (bad merge). Fixed, with a test and CI so it cannot recur silently.
- **Main risks:** unsigned/untested release build; production is the only database and is edited by hand; several owner decisions on attendance rules are unconfirmed.

## 2. Statistics
| | |
|---|---|
| Files in scope | 263 app source files, 30 test files, Android/iOS config, 57 database functions, 13 tables, 17 policies, 2 Edge Functions. Read in full this session: entry point, router, DI, auth, attendance, permissions, admin and review code, push code, all security-relevant database functions. Not every UI widget file was re-read |
| Issues identified | 30 distinct (items listed in two reports counted once) |
| Fixed in this audit | 5 (A-1, A-2, S-2, S-6, P-4) |
| Remaining | 25 (2 P1, 9 P2, 14 P3) |
| Automated tests | 389 run, 389 passed, 0 failed; 1 backend test blocked (missing module) |
| Device / role / load tests | 0 run |

## 3. Security
| | |
|---|---|
| Vulnerabilities found | No exploitable flaw found in code or database rules |
| Hardening fixed | Session excluded from Android backups; location details removed from device logs |
| Database | RLS on every table; clients read-only; no anonymous access; every admin function checks the role; all privileged functions pin `search_path` |
| Remaining | Debug-key signing (P1); leaked-password protection off; Auth settings unverified; `net` HTTP functions granted to client roles; two permissive Storage policies that would matter with a second bucket |
| Not done | Penetration test; acting as each role against the database (blocked) |

## 4. Functional QA
All main workflows are covered by automated tests against fakes that mirror the database functions
(see 02). Roles covered: employee, delegated reviewer, admin, suspended. **No workflow was executed
against the real backend or on a device.**

## 5. Compatibility
Android release builds for three ABIs and an App Bundle: built. Layouts tested at 320–430 px, two
text scales, Arabic and English, light and dark. **Devices tested: none. iOS release: never built.**

## 6. Performance
| Metric | Before | After |
|---|---|---|
| Download size (arm64) | 65.3 MB single APK | 23.0 MB split APK / App Bundle delivery |
| Requests on app resume | attendance loaded twice | once |
| Startup, memory, CPU, frames, API and query times | **not measured (no device; 8 rows of data)** | — |

## 7. Builds
Android APK ×3: built. Android App Bundle: built. iOS: not built. Build errors: none after the
`main.dart` fix. Runtime validation: none.

## 8. Remaining issues (P1 and P2)
| ID | Sev | Issue | Impact | Root cause | Resolution |
|---|---|---|---|---|---|
| S-1 | P1 | Release signed with the debug key | Stores reject it; anyone can sign an "update" | No keystore yet | Create the keystore, add `android/key.properties` (09) |
| F-1 | P1 | No real-device, real-account run of the release build | Unknown startup/flow failures reach employees | No device attached; production-only backend | Run the checklist in 05/09 |
| D-1 / A-6 | P2 | Schema edited by hand in production, no staging | One mistake affects everyone (it already happened once) | No migration workflow | Files + dry run; a test project |
| D-5 / S-4 | P2 | Auth settings unverified | Suspended users might still sign in; reset links might not open | Not readable through the tools | Check four dashboard settings (09) |
| S-3 | P2 | Leaked-password protection off | Known-breached passwords accepted | Default setting | Switch it on |
| F-2 | P2 | Check-in refused after 16:00 | A late arrival cannot be recorded | Rule in `check_in` | Confirm or change |
| F-3 | P2 | Lateness subtracts the grace period | 20 min late is stored as 5 | Generated column | Confirm or change |
| U-1 | P2 | No visual review on a device | Layout problems only a screen shows | No device | Part of the device pass |
| P-1 | P2 | No measured performance | Unknown on low-end phones | No device | Profile build on a cheap phone |
| C-1 | P2 | iOS never built (see 05, 09) | Unknown iOS state | No Mac | Ship Android first, or archive on a Mac |
| T-1 | P2 | No tests against a real database (see 08) | RLS/function regressions undetected | No test project | A second Supabase project |

The P3 items are listed in reports 01–07.

## 9. What was changed in this audit
| File | Change |
|---|---|
| `lib/main.dart` | Compile errors fixed: one router with the permission guard; duplicate resume reload removed |
| `test/app_compiles_test.dart` | New: fails tests if the entry point does not compile |
| `.github/workflows/ci.yml` | New: analyze, test, release APK on pull requests |
| `android/app/src/main/AndroidManifest.xml`, `res/xml/data_extraction_rules.xml` | Backups and device transfer of app data disabled |
| `android/app/build.gradle.kts` | Release signing from `android/key.properties` when present |
| `lib/core/services/address_service.dart` | Logs the error type only |

`pubspec.yaml` is unchanged: `cupertino_icons` is unused but left in place (P3), and `supabase` is
needed by one test.

Database: nothing changed. Nothing committed.

Final regression after all changes: `flutter analyze` 0 errors, 0 warnings, 6 infos; `flutter test`
389 passed, 0 failed.
