# 06 — Audit: employee management, permissions, live notifications (2026-11-13)

Labels: **tested** = executed here and passed · **not verified** = written, could not be run for
real · **not done** = with the reason.

**Blocker for this round:** the Supabase connector was no longer attached to the session, so the live
database could not be read or changed. Everything below that needs the database says so. No phone
or emulator is attached, and there are no test accounts on the (production-only) backend, so nothing
was run with real accounts or on a device.

## 1. Problems found
| # | Problem | Cause |
|---|---|---|
| 1 | Notifications appear only after closing and reopening the app | The list was loaded only when the account changed or the app came back to the foreground. Nothing listened while the app stayed open |
| 2 | Push while the app is closed | Fixed in the previous round (reports 02); still no delivery seen on a phone |
| 3 | "Edit / delete employee is missing from the interface" | **Not reproduced: both exist** (see 3). The installed build may predate them |
| 4 | "Assigning permissions is missing" | **Partly true.** A permissions screen exists, but the live database only has three per-employee permissions (see 4) |
| 5 | One notification of a type the app doesn't know emptied the whole list | Parsing threw on the first unknown row |
| 6 | Sign-in and password error texts were English in the Arabic app | Validators had fixed English strings |
| 7 | "Try again" on every error screen was English in Arabic | Fixed string in the shared error view |
| 8 | An empty email field could crash the validator | Null was force-unwrapped |
| 9 | A permission removed while the app is open only showed after going to the background and back | Refreshed on resume only |

## 2. Changes implemented
| File | Change |
|---|---|
| `notifications/data/inbox_repository.dart` | `watch()`: a Supabase Realtime channel on the account's own notifications; fires on every change and each time the connection (re)opens. Unknown rows are skipped |
| `notifications/presentation/inbox_cubit.dart` | One live subscription per signed-in account, released on sign-out; quiet refresh (no progress bar, no error banner, loaded pages kept, never interrupts a manual load) |
| `lib/main.dart` | Quiet inbox check every 20 s while the app is open (covers a dropped connection or a database without live updates); permissions re-read every minute |
| `core/functions/form_validator_functions.dart` + 3 auth forms | Messages in the app language; null-safe |
| `core/widgets/states/app_error_view.dart` | "Try again" localized |
| `lib/l10n/app_ar.arb`, `app_en.arb` | 8 validator strings |
| `supabase/migrations/20261113100000_notifications_realtime.sql` | **Not applied.** Adds `notifications` to the Realtime publication |
| Tests | New `test/notification_live_test.dart` (10); 1 added to `single_session_test.dart`; fakes updated |

## 3. Employee management
| Asked | State | Evidence |
|---|---|---|
| Edit action on the employee profile | Exists: **Edit details / تعديل البيانات** on Admin → employee | `employee_details_view.dart`; widget tests |
| Edit full name, username, employee code | Works through `admin_edit_employee_profile`, with validation, saving state, messages and reload | tested (fakes) |
| Change login email | Works: the admin requests it, the employee confirms | tested (fakes) |
| Change work schedule | Works: **Change schedule** | tested (fakes) |
| Edit phone | **Not done.** The database has no function that changes `profiles.phone` after creation | needs a database function |
| Job title, department | **Not done.** The database has no such columns | needs a schema decision |
| Delete | Done as **Deactivate account / إيقاف الحساب**: confirmation naming the employee; attendance, cash and correction history kept; can be re-activated | tested (fakes) |
| A deactivated employee cannot use the app | Database refuses at once (`is_active`), sign-in is refused by the login hook, and an open app signs out within a minute | database rule read earlier; new app test |
| Only admins | `admin_*` functions call `require_actor(true)`; the router blocks the pages; admins cannot deactivate themselves or other admins | read from the live database on 2026-11-12 |

A hard delete is deliberately not offered: every attendance, request and audit row references the
employee with `ON DELETE RESTRICT`.

## 4. Permission system
What is live (designed in the database by its owner, and enforced there):

| Permission | Lets the employee |
|---|---|
| Review assigned cash requests | Approve or reject the cash requests an admin assigns to them |
| Review assigned attendance corrections | The same for corrections (a written reason is mandatory) |
| Review assigned overtime | Stored; the app has no overtime screen |

- **Where:** Admin → employee → **Permissions / الصلاحيات**: switches per employee, a summary of the changes before saving, and who may be changed.
- **Granting / revoking:** `admin_set_*_reviewer_permission`, admin role only, employees only, never yourself. An employee cannot grant anything.
- **Effect:** the database applies it on the next request; the app now re-reads it every minute and on resume, so screens and shortcuts follow without a restart.
- **A reviewer sees only what is assigned to them**, without the requester's name (your earlier decision), and cannot review their own request.
- **Admins** hold every admin function through their role; that is not a per-person switch, so the last admin cannot be removed from the app.

**Not done: the wider list in the request** (view all cash requests, approve without assignment, view
attendance, edit employees, reports, export — each grantable per employee). That is a different
model from the live one. It needs a new permissions table and a rewrite of every read policy and
about twenty functions in production. Earlier in this project that design (`20261111090000_permissions.sql`)
was set aside in favour of the reviewer flags. I did not start it without your decision, and could
not have applied it this round anyway.

## 5. Notifications
| State | How | Status |
|---|---|---|
| App open | Live channel + 20 s quiet check + push arriving in the foreground → list and badge update, with an in-app message for a push | **tested** with a simulated server (10 tests). The live channel itself is **not verified**: it needs the migration below and a real backend run |
| Without that migration | The 20 s check alone keeps the list at most 20 s behind while the app is open | tested (logic) |
| Internet returns | The channel re-opens and triggers a reload; the 20 s check also catches up | tested (simulated) |
| Background / closed / locked | Server push through Firebase (previous round) | **not verified on a phone** |
| iOS push | — | **not done**: no Apple/APNs configuration |
| Recipients | New request → admins (not the requester); assigned → that reviewer; decision → the requester. Enforced by database triggers and row-level security | read from the live database on 2026-11-12 |
| Duplicates | Lists are keyed by id; one push delivery per notification and phone | tested |
| Permission changed → notify the employee | **Not done**: the notifications table only allows request events; needs a schema change |

## 6. Test results
| Command | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 4 infos |
| `flutter test` | **443 passed, 0 failed** (432 before this round) |
| `node --test supabase/tests/*.mjs` | 8 passed, 0 failed |
| `flutter build apk --release --split-per-abi` | Built (arm64 23.2 MB) |

**Not run, and why**
| Asked | Reason |
|---|---|
| Multi-account tests on the real backend (admin, two reviewers, plain employee) | No test accounts exist; production is the only database; no database access this round. The role rules were verified earlier by reading the live functions and policies, and in the 2026-11-12 production dry run for sessions |
| Direct API calls as an unauthorised user | Same |
| Push in background / terminated; two devices | No device |
| Run the built APK | No device or emulator attached |
| iOS build | No Mac |

## 7. Database changes
| Migration | State |
|---|---|
| `20261113090000_single_session_push_reasons.sql` | **Applied** 2026-11-12 22:08 UTC (previous round) |
| `20261113100000_notifications_realtime.sql` | **Not applied** — needs your approval and database access |
| Phone edit, job title / department, permission-change notification, granular RBAC | Not written: each needs a schema decision from you |

## 8. Remaining issues
| Issue | Severity |
|---|---|
| Nothing in this project has yet been run on a real phone with real accounts | High |
| Push delivery never observed | High |
| Granular per-employee permissions beyond the three reviewer switches | Open decision |
| Phone / job title / department editing | Needs database changes |
| Live channel needs the publication migration; until then updates take up to 20 s | Medium |
| Release still signed with the debug key | High (from the audit) |
| iOS push | Not implemented |

## 9. Deployment
1. Re-attach the Supabase connector (or use the SQL editor) and run `supabase/migrations/20261113100000_notifications_realtime.sql`.
2. Build: `flutter build apk --release --split-per-abi` (or `flutter build appbundle --release` once `android/key.properties` exists).
3. Install `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` on two phones and run the test tables in 01, 02, 04 and section 5 here.
