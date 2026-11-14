# 01 — Single active session (2026-11-13)

**Status: FIXED BUT NOT FULLY VERIFIED.** The database rule is live since 2026-11-12 22:08 UTC
(applied on your approval, after a rolled-back dry run on real sessions passed). It has not been
exercised with two real phones, and the new app build is not released yet.

## Root cause
Supabase Auth creates one independent session per sign-in and nothing compared them. Read on
2026-11-12: one account held 14 live sessions. The database rules (`private.is_active()`,
`private.require_actor()`) checked the account only, never which session was asking.

## Design
The active session of an account is its **most recently created Auth session**.

| Requirement | How it is met |
|---|---|
| Server-authoritative | `private.session_is_current()` compares the `session_id` in the signed access token with `auth.sessions`, which only Supabase Auth writes. The phone cannot choose the active session |
| Enforced on every protected request | The check is added to the five helpers every RLS policy uses (`is_active`, `is_admin`, `can_review_*` ×3) and to `require_actor`, which every write function calls. Covers tables, Storage selfies and all RPCs |
| Previous phone loses access at once | The moment the new session exists, the old one is no longer the newest: its very next request is refused, without waiting for anything |
| Previous phone cannot refresh | The new phone's first account load (`get_account_status`, called right after sign-in) deletes the account's older sessions; their refresh tokens go with them |
| Atomic, race-safe | No separate "active session" row to update. Two sign-ins at the same instant are ordered by `(created_at, id)`: exactly one wins |
| Session records | `auth.sessions` already stores id, user, created, last refresh, IP and user agent. No new table, no client-made device id used for security |
| Sign-out | Unchanged: ends the server session (local scope), removes the push registration, clears local state. The account can sign in again anywhere |
| No account data to a replaced phone | `get_account_status` returns only `session_state` (`replaced` / `ended`) to it |

The login hook (`attendance_access_token_hook`) is **not changed**: a mistake there would lock
everyone out, and the design does not need it.

### On the replaced phone (Flutter)
- `SupabaseAuthRepository` reads `session_state`; `replaced` → local sign-out + `AuthFailureReason.sessionReplaced`.
- `AuthCubit.verifySession()` runs at startup, every time the app returns to the foreground, and once a minute while it is open. Offline or a server error is not treated as a verdict (the session is kept).
- The user lands on the sign-in screen with: «تم تسجيل الدخول إلى حسابك من جهاز آخر. يرجى تسجيل الدخول مرة أخرى للمتابعة.» No raw error is shown.
- Attendance, permissions and inbox data in memory are cleared by the existing sign-out path.

The one-minute check is only for the message and the screen change. Security does not depend on it:
the database refuses the old session by itself.

## Files
| File | Change |
|---|---|
| `supabase/migrations/20261113090000_single_session_push_reasons.sql` | Section 1: `session_is_current`, the six helpers, `get_account_status` |
| `supabase/backups/20261113_rollback.sql` | Restores the previous definitions |
| `supabase/verify/20261113_dry_run.sql` | Dry run that ends in `ROLLBACK` |
| `lib/core/errors/failure.dart`, `auth_failure_text.dart` | `sessionReplaced` + message |
| `lib/app/features/auth/data/repositories/supabase_auth_repository.dart` | Reads `session_state`; keeps the session on inconclusive errors |
| `lib/app/features/auth/presentation/manager/auth_cubit/*` | `verifySession()`, `noticeShown()` |
| `lib/app/features/auth/presentation/views/login_view.dart` | Shows the reason also when the screen opens because of it |
| `lib/main.dart` | Check on resume and every minute |
| `lib/l10n/app_ar.arb`, `app_en.arb` | `authSessionReplaced` |

## Tests run
**Database** — the real migration file on an in-memory Postgres (`supabase/tests/single_session_push_reasons.test.mjs`): **passed**.

| # | Matrix item | Result |
|---|---|---|
| 1–2 | Sign in on A, then on B | A active, then B active |
| 3, 5 | A loses access; A calls the API | `is_active()` false, `require_actor()` 42501, no account data |
| 4 | B stays signed in | active, full account |
| 6 | A refreshes its token | A's session row (and so its refresh tokens) is deleted by B's first load — asserted on the row; the refresh call itself needs the real Auth server |
| 7–8 | B signs out; A signs in again | A's old session does **not** come back; a new sign-in works |
| 9 | Simultaneous sign-ins | exactly one of three sessions active |
| — | Forged, foreign or missing session id | never active |
| — | Other accounts | unaffected |

**App** (`test/single_session_test.dart`, 10 tests): **passed** — replaced → signed out with the Arabic message on the sign-in screen; ended otherwise → signed out without a misleading reason; offline/server error → stays signed in; app restart on the replaced phone; no duplicate checks; can sign in again.

## Not verified
| Item | Why |
|---|---|
| Two real phones against the real backend | Migration not applied; no device attached |
| Item 10, network loss during replacement, on devices | Same. In tests an offline check keeps the session and the next check decides |
| Token refresh refused by the real Auth server | Same |
| Reinstall / device identifier change | No device. By design neither matters: a reinstall has no session and signs in as a new one |

## Limits to know
- **Applying the migration signs out every phone except the most recent one per account** (some accounts have many old sessions). Expected, but tell the team.
- For up to about a second (until the new phone's first account load) the old phone's refresh token still exists. The database already refuses its access token during that time.
- The `employee-accounts` Edge Function checks the token with Supabase Auth, so it refuses the old phone once that deletion has happened, not before.
- A phone that stays open notices within a minute; it is not pushed a sign-out instantly.
- A password-reset link opens a new session, which becomes the active one.
