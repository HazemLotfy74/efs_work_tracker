# 05 — Integration and regression results (2026-11-13)

Labels: **run** = executed here · **simulated** = executed against a fake or an in-memory Postgres ·
**blocked** = could not be executed.

## Commands
| Command | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 4 infos (3 in generated code, 1 style note) |
| `flutter test` | **432 passed, 0 failed** (389 before this work) |
| `node --test supabase/tests/*.mjs` | **8 passed, 0 failed** (was 1 passed, 1 blocked) |
| `flutter build apk --release --split-per-abi` | Built; arm64 23.1 MB |
| iOS build | blocked (no Mac) |
| `integration_test/` | none exist |
| Migration against production | **not applied**; dry-run script provided |

The backend tests need `@electric-sql/pglite` installed in `<temp>/efs-notification-verification`
(done on this machine; not part of the repo or CI).

## Cross-feature checks
| Interaction | Evidence | Label |
|---|---|---|
| New phone becomes the push destination | Registering from the active session removes the account's other phones | simulated |
| Old phone gets no more alerts | Sender skips a phone whose session is not the newest, even before the new phone registers | simulated |
| Replacing a session never hits the new phone | Only the active session can delete others; a replaced phone asking for its status deletes nothing | simulated |
| Sign-out removes the phone's registration | Existing `unregister_push_device` + session cascade | simulated |
| Opening a notification checks the current session | Reads go through RLS, which now includes the session check | simulated |
| Correction submitted → admins notified | Existing trigger, read from the live database | inspected |
| Approved / rejected → the employee notified, once | Existing trigger fires only when the status changes; unique delivery key | inspected + simulated |
| Decision without a reason → no status change, no notification | Rule on the table rolls the whole call back | simulated |
| Reason shown to the employee | History card and notification detail | simulated (widget tests) |
| App works before and after the migration | `session_state` and the new sender fields are optional on both sides | simulated |

## Blocked
| Test | Why |
|---|---|
| Two-phone sign-in on the real backend | Migration not applied; no device |
| Real push delivery in any app state | No device; no phone registered in production |
| iOS, everything | Push not implemented; no Mac |
| Old token refresh refused by the real Auth server | Needs the migration and a device |
| Concurrency under real load | Production is the only database |

## Regressions found and fixed during this work
| Found by | Problem | Fix |
|---|---|---|
| New widget test | "Signed in on another device" never shown: the sign-in screen opened after the state change | The screen reads the reason when it opens |
| New widget test | Empty/error state threw a layout error inside pull-to-refresh | Fixed height for the state view |
| New SQL test | A reason of only line breaks was accepted | Rule requires a non-whitespace character |
| New SQL test | The table check passed when the note was `NULL` | Explicit not-null |
| Existing tests (8) | Reviewed corrections without a reason | Tests updated to the new rule |
