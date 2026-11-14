# 04 — Security audit (2026-11-12)

No penetration test was run against production. This is a configuration and code review plus the
static database checks in 03.

## Authentication [read]
| Item | Result |
|---|---|
| Method | Email + password only; no self sign-up (accounts are created by an admin through an Edge Function with the service key held server-side) |
| First sign-in | Forced password change; 12 characters minimum, enforced server-side |
| Suspension | Database refuses every read/write for an inactive account; token refresh refused by the access-token hook **if the hook is enabled** (not verifiable from here) |
| Password reset | Custom scheme `efsworktracker://reset-password`; another app could register the same scheme, but supabase_flutter's default PKCE flow needs a verifier stored on this phone, so an intercepted link alone is not enough |
| Brute force | Supabase Auth's built-in rate limits (settings not readable) |
| Session storage | supabase_flutter default: SharedPreferences (app-private, **not** encrypted at rest) |

## Authorization [read]
Enforced in the database on every call (03). The app's permission checks only decide what is shown.
No IDOR path found: every function takes the actor from the session; list reads are constrained by RLS.

## Secrets [run]
Scan of `lib/`, `android/`, `ios/`, `supabase/`, CI files: **no service-role key, private key, password
or token**. The Supabase publishable key in `constants.dart` is public by design.
`android/app/google-services.json` is committed: it holds Firebase client identifiers, not secrets —
restrict the API key to this app's package and signing certificate in the Google Cloud console.

## Mobile configuration
| Item | Before | After |
|---|---|---|
| Android backups of app data (session token) | allowed by default | **disabled** (`allowBackup=false`, data-extraction rules) — confirmed in the merged release manifest [run] |
| Release `debuggable` | not set (false) | unchanged [run] |
| Cleartext HTTP | blocked by default (target SDK 36); every endpoint is HTTPS | unchanged |
| Exported components | main activity + Firebase receivers | unchanged |
| Permissions | location, internet, notifications (+ plugin-added network state, wake lock, FCM) | unchanged; no camera permission (system camera app is used) |
| iOS ATS | no exceptions | unchanged |
| Device logs | geocoder errors printed in full (could include coordinates in a URL) | **only the error type is printed** |
| **Release signing** | debug key | **wired to `android/key.properties`; no key exists yet → still the debug key** |

## Dependencies [run]
`flutter pub outdated`: nothing discontinued or retracted; only minor/patch updates available
(go_router 18.1.4, flutter_svg 2.3.4, geocoding 5.0.1, transitive plugins). No upgrade was made:
none fixes a known problem and each would need a device regression run. No vulnerability scanner
for pub packages was available here.

## Findings
| ID | Sev | Finding | Status |
|---|---|---|---|
| S-1 | **P1** | Release builds are signed with the debug key | **Open — you must create the upload keystore** (see 09) |
| S-2 | P2 | Session token included in Android backups | **Fixed** |
| S-3 | P2 | Leaked-password protection off | Open — one switch in the dashboard |
| S-4 | P2 | Auth settings unverified (hook enabled, sign-ups disabled, redirect URLs, email-change confirmation) | Open — check in the dashboard |
| S-5 | P3 | Session stored unencrypted in SharedPreferences | Open — acceptable with S-2 fixed; `flutter_secure_storage` is the upgrade path (new dependency, needs device testing) |
| S-6 | P3 | Coordinates could reach device logs | **Fixed** |
| S-7 | P3 | No root/jailbreak or screenshot protection | Open — not required for this app class |
| S-8 | P3 | Database items D-2, D-3 | Open |
