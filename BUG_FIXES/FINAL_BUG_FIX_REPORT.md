# Final bug-fix report (2026-11-13)

## Status
| # | Issue | Status | What is missing |
|---|---|---|---|
| 1 | Single active session | **FIXED BUT NOT FULLY VERIFIED** | Live in the database; no two-phone test yet |
| 2 | Push notifications | **PARTIALLY FIXED** | Server side live; no delivery seen on a phone; iOS not implemented |
| 3 | Notification screen | **FIXED BUT NOT FULLY VERIFIED** | Not seen on a real device |
| 4 | Mandatory decision reason | **FIXED BUT NOT FULLY VERIFIED** | Live in the database and the app; not exercised on a device |

## Deployment (2026-11-12 22:08 UTC, on your approval)
| Step | Result |
|---|---|
| Live state re-read before the change | Unchanged since the design (no object of the migration existed) |
| Dry run in production, rolled back | Passed: on a real account with several sessions the newest was accepted and the oldest refused by `is_active()` and `require_actor()`; every account had exactly one active session; a decision without a reason on the real pending request was refused with `22023` |
| Migration applied (one transaction) | Committed. 12 functions, 1 constraint (`NOT VALID`), 1 trigger in place; grants as intended (no client role can call `session_is_current` or `claim_push_deliveries`) |
| Data | Row counts unchanged: 3 correction requests, 24 Auth sessions (older ones are removed only when their account next loads on its active phone) |
| Active sessions now | 4 accounts signed in, exactly 1 active session each |
| `send-notification-push` | Version 5 deployed, same JWT setting as before (it authenticates itself) |
| First scheduled sender run after both changes (22:09 UTC) | HTTP 200, `{"sent":0,"retry":0,"failed":0,"leasePending":0}`: the new sender authenticates, reaches Google and calls the new queue function. Nothing to send: no phone is registered |
| Security advisors after the change | No new finding |

**Effect on phones today:** each account keeps working only on the phone that signed in most
recently. Other phones get empty screens or "account unavailable" with the build they have now, and
the Arabic "signed in on another device" message once they run the new build.

Rollback, if needed: `supabase/backups/20261113_rollback.sql`.

## 1. Root causes
1. Supabase Auth gives each sign-in its own session and no rule compared them (one account had 14).
2. No phone was ever registered for push (0 rows): the feature was compiled out by default and then hidden behind a bell icon, so users only saw the in-app list when they opened the app. Also no Android channel, generic text, up to 60 s cron delay.
3. The Alerts screen used default Material widgets, not the app's design system.
4. The review functions and the dialog treated the note as optional; the table did not require it.

## 2. Implementation — see reports 01–04

## 3. Modified files
**App:** `lib/main.dart`, `lib/core/errors/failure.dart`,
`auth/{data/repositories/supabase_auth_repository, presentation/manager/auth_cubit/auth_cubit, auth_state, presentation/views/login_view, presentation/widgets/auth_failure_text}.dart`,
`notifications/{data/phone_alerts, data/inbox_repository, presentation/inbox_cubit, presentation/inbox_view}.dart`,
`attendance_correction/{data/repositories/supabase_correction_repository, presentation/widgets/review_decision_dialog, correction_review_card, correction_request_details}.dart`,
`assigned_reviews/{data/repositories/supabase_assigned_review_repository, presentation/views/assigned_reviews_view}.dart`,
`admin/data/repositories/supabase_admin_repository.dart`, `lib/l10n/app_ar.arb`, `app_en.arb` (+ generated).

**Android:** `AndroidManifest.xml`, `MainActivity.kt`.

**Backend (files only):** `supabase/functions/send-notification-push/index.ts`,
`supabase/migrations/20261113090000_single_session_push_reasons.sql`,
`supabase/backups/20261113_rollback.sql`, `supabase/verify/20261113_dry_run.sql`.

**Tests:** new `test/single_session_test.dart`, `test/notification_inbox_view_test.dart`,
`supabase/tests/single_session_push_reasons.test.mjs`; updated `test/attendance_correction_test.dart`,
`test/delegated_reviews_test.dart`, `supabase/tests/send_notification_push.test.mjs`.

## 4. Database migration (one file, one transaction, additive)
| Adds / replaces | Risk |
|---|---|
| `private.session_is_current()`; session check in `is_active`, `is_admin`, `can_review_*`, `require_actor` | **Signs out every phone except the newest per account.** A mistake here would block all reads — which is why it is tested and has a dry run and a rollback |
| `get_account_status` reports `session_state` and ends older sessions | Becomes `VOLATILE` |
| `register_push_device`, `claim_push_deliveries` (two more columns), `enqueue_notification_push` | The deployed sender ignores the extra columns; either order of deployment works |
| Check + trigger on `attendance_correction_requests` | `NOT VALID`: history untouched. Brief lock on the table |

No table or row is dropped. `list_migrations` is empty for this project (changes are made by hand),
so there is no migration history to conflict with.

## 5. Backend changes
Edge Function `send-notification-push`: text per event, high priority, `alerts` channel, 24 h TTL.
Not deployed.

## 6. Security improvements
- Session validity enforced in the database on every read and write, not in the app.
- A replaced phone gets no account data, cannot register for push and stops receiving alerts.
- A session is not ended by an inconclusive error; only by a definite server answer.
- Decision reasons enforced on the table, immune to direct API calls once applied.
- No secret added to the app; no security rule weakened.

## 7–11. Tests
| | |
|---|---|
| Executed | `flutter analyze`; `flutter test` (432); `node --test` (8); Android release build |
| Passed | 432 + 8; build succeeded |
| Failed | 0 at the end (4 defects found on the way and fixed, and 8 older tests updated to the new rule — see 05) |
| Blocked | Everything on a real device; everything on iOS; everything against the live backend |

## 12. Needed from you
1. Tell the team that only the most recently signed-in phone per account still works.
2. Install this build on two Android phones and run the three test matrices (01, 02, 04).
3. For iOS push: Apple Developer account, APNs key in Firebase, `GoogleService-Info.plist`, a Mac.
4. Still open from the audit: a release signing key (and its SHA in Firebase).

## 13. Remaining risks
| Risk | Severity |
|---|---|
| The new app build is not released yet: phones on the old build that lose their session see empty data instead of the explanation | Medium |
| Push has never been seen arriving on a phone | High |
| iOS users get no push | Medium |
| A phone left open learns of the replacement within a minute, not instantly | Low |
| Push text is Arabic only | Low |
| Signing in on a second phone by mistake signs the first one out — that is the rule asked for | Note |
