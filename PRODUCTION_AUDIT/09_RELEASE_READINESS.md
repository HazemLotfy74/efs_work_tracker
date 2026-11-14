# 09 — Release readiness (2026-11-12)

## Android [run]
| Item | Value | OK? |
|---|---|---|
| Application id | `com.efs.efs_work_tracker` | yes |
| Version | 1.0.0 (code 1) | yes for a first release |
| minSdk / targetSdk | 24 / 36 | yes |
| Release APKs / App Bundle | built | yes |
| Debuggable | no | yes |
| Backups | disabled | yes (fixed) |
| R8 keep rules for the earlier white-screen crash | present (`proguard-rules.pro`) | yes |
| Obfuscation (`--obfuscate --split-debug-info`) | not used | optional |
| **Signing** | **debug key** | **NO — blocker** |
| Push | only when built with `--dart-define=ENABLE_PHONE_ALERTS=true` | decide and document the build command |

### To sign the release (your action — I must not create or hold your signing key)
1. Create an upload keystore once and keep it and its passwords somewhere safe (losing it blocks updates):
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` (already git-ignored):
   ```
   storeFile=../upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. Build: `flutter build appbundle --release` (the Gradle file now uses this key automatically).
4. Add the key's SHA-1 / SHA-256 to the Firebase project, or push will not work in the signed build.

## iOS
| Item | Value |
|---|---|
| Bundle id | `com.efs.efsWorkTracker` |
| Deployment target | 15.0 |
| Permission texts | location, camera present |
| Signing team / provisioning | **not configured** |
| Release archive | **never built** (needs a Mac; Codemagic only builds a debug simulator app) |
| Push | not implemented on iOS |

## Startup validation
**Not done in this audit.** The release build was not installed or launched: no device was attached.
History: a release-only white screen (R8 removing methods a plugin calls) was fixed earlier and its
keep rules are still in place, but since then Firebase messaging, the inbox and a merge that broke
`main.dart` have landed. **The current release build has never been seen running.**

## Launch checklist
- [ ] Upload keystore created; signed App Bundle built
- [ ] Signed release APK installed on 2–3 real Android phones; launch, sign-in, check-in, check-out pass (05)
- [ ] Dashboard: leaked-password protection on; public sign-ups off; access-token hook enabled; redirect URL `efsworktracker://reset-password` listed
- [ ] Password-reset email opens the app on a real phone
- [ ] Decide: push on or off for v1 (and test it if on)
- [ ] Commit and push the audit fixes so CI starts running
- [ ] iOS: archive on a Mac, or ship Android first
