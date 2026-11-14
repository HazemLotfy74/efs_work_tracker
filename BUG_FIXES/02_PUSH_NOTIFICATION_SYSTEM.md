# 02 — Push notifications (2026-11-13)

**Status: PARTIALLY FIXED.** Android code is complete and builds; the server side is tested locally.
The server changes are live since 2026-11-12 22:08 UTC (migration applied, sender version 5 deployed).
**No push has been delivered to a real phone** (no device attached, and no phone is registered yet),
and **iOS push is not implemented** (needs Apple configuration nobody has yet).

## What exists (inspected)
Business event → trigger `notify_request_event` → row in `public.notifications` → trigger
`enqueue_notification_push` → `private.push_deliveries` → Edge Function `send-notification-push`
(called by a cron job every minute) → Firebase Cloud Messaging HTTP v1 → Android.
The Firebase service account lives only in the Edge Function's secrets; the app never holds it.

Events that notify (existing rules, none added):

| Event | Recipient |
|---|---|
| Request submitted (correction, cash, overtime) | every active admin except the requester |
| Request assigned to a reviewer | that reviewer |
| Request approved / rejected | the employee who made it |

Check-in and check-out do not create notifications in the current design; I did not invent one.

## Root causes
| # | Cause | Evidence |
|---|---|---|
| 1 | **No phone was ever registered**, so nothing was ever sent | `private.push_devices` has 0 rows; all 274 sender runs answered `{"sent":0,…}` |
| 2 | Push was compiled out unless the build passed `--dart-define=ENABLE_PHONE_ALERTS=true` | `phone_alerts.dart` |
| 3 | Even then the user had to find and tap a bell icon on the Alerts screen | `inbox_view.dart` |
| 4 | So "notifications" were only the in-app list, refreshed when the app is opened or resumed — hence late, and never while the app is closed | `main.dart` |
| 5 | Once working, delivery would wait up to 60 s for the next cron minute | `cron.job` |
| 6 | No Android notification channel: alerts would fall into the silent default channel (no sound, no banner) | manifest, `MainActivity` |
| 7 | Every alert said only "You have a new notification." and expired after 5 minutes offline | Edge Function |

## Fixes
| Area | Change |
|---|---|
| App | Push is on by default (`ENABLE_PHONE_ALERTS=false` turns it off). The notification permission is asked once after the first sign-in on a phone; the bell stays for asking again |
| App | While the app is open, an arriving push refreshes the list and badge and shows an in-app message (Android shows nothing itself in the foreground) |
| Android | High-importance channel `alerts` created in `MainActivity`; set as the default FCM channel in the manifest. `POST_NOTIFICATIONS` was already declared |
| Sender | Text by event and request type (Arabic, no personal data on the lock screen); `priority: HIGH`; channel `alerts`; kept 24 h for an offline phone; works before and after the migration |
| Database | The sender is woken as soon as a notification is queued (cron stays as the retry path); a sender failure can never undo the business change |
| Database | A phone can register only from the account's active session; registering removes the account's other phones; the sender skips any phone whose session is no longer the newest |

Already correct and kept: retries with back-off (up to 8), invalid-token cleanup (`UNREGISTERED`),
one delivery per notification and phone (unique key + lease), FCM `tag` so a retry replaces rather
than duplicates, token refresh handling, token removal on sign-out, tap → Alerts screen including
cold start, and `mark_notification_read`/RLS deciding what the user may open.

## Files
`lib/app/features/notifications/data/phone_alerts.dart`, `lib/main.dart`,
`android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/.../MainActivity.kt`,
`supabase/functions/send-notification-push/index.ts`,
`supabase/migrations/20261113090000_single_session_push_reasons.sql` (section 2),
`supabase/tests/*.mjs`.

## Tests run
| Test | Result |
|---|---|
| Sender: auth, text per event, channel, priority, TTL, retry delay, invalid token (`send_notification_push.test.mjs`) | passed |
| Queue SQL, original (`notification_push.test.mjs`) — previously blocked, now runs | passed |
| Queue SQL after migration: only the active session's phone, woken at once, subject returned, no double claim, client roles refused, failing sender harmless | passed |
| Android release build with the channel code | built |

## Delivery tests — all blocked
| State | Result |
|---|---|
| Foreground / background / minimized / terminated / locked | **Not tested — no device** |
| Permission denied / granted (Android) | Not tested |
| Offline then online, token refresh | Not tested |
| Sign-out and sign-in on another phone | Simulated in SQL only |
| Tap and navigation | Not tested on a device |
| iOS, every item | **Not possible: not implemented** |

## Needed from you
**Android**
1. Done: migration applied, `send-notification-push` version 5 deployed.
2. Install the new build on a phone, sign in, allow notifications, then have another account submit and decide a request with the app in each state above.
3. Once a release keystore exists, add its SHA-1/SHA-256 to the Firebase project.

**iOS (nothing can be claimed until all of this is done)**
1. Apple Developer account; an APNs authentication key uploaded to the Firebase project.
2. An iOS app in Firebase and its `GoogleService-Info.plist` in `ios/Runner`.
3. Push Notifications capability, `aps-environment` entitlement and Background Modes → Remote notifications in Xcode (needs a Mac).
4. Then remove the Android-only gate in `PhoneAlerts.initialize` and test on a real iPhone (the simulator is not enough).

## Limits
- Delivery is never guaranteed: Android may delay alerts in Doze, and some manufacturers stop background apps unless the user exempts the app from battery optimisation.
- Push text is Arabic only. The in-app list follows the app language.
- The decision reason is not in the push text (it would show on a lock screen); it is shown in the app.
