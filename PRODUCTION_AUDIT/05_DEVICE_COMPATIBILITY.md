# 05 — Device compatibility (2026-11-12)

**Nothing in this audit ran on a phone, an emulator or a simulator.** None was attached to this
machine. Everything below is build validation or automated layout testing only.

| Level | What |
|---|---|
| Actually tested on a device (this audit) | **none** |
| Simulator / emulator tested (this audit) | **none** |
| Build-validated [run] | Android release APKs for arm64-v8a, armeabi-v7a, x86_64 and a release App Bundle |
| Layout-tested in widget tests [run] | 320, 360, 390, 430 px widths; text scale 1.0× and 1.3×; Arabic (RTL) and English; light and dark |
| Earlier, by another session (not re-verified) | A release APK installed on one Redmi Note 8 Pro after a white-screen fix; the first frame was not observed |
| iOS | **Never built for release.** Codemagic builds a debug simulator app only. Deployment target 15.0. No signing team configured |

## Android configuration [run]
minSdk 24 (Android 7.0), targetSdk 36, 64-bit and 32-bit ARM builds produced.

## Platform differences to know
- **Push notifications are Android-only** (`PhoneAlerts.initialize` returns `null` elsewhere, and only when built with `--dart-define=ENABLE_PHONE_ALERTS=true`). iOS users get the in-app inbox only.
- Camera: the system camera through `image_picker` (no in-app camera).
- Location: `geolocator`, foreground only; no background location.

## Required before launch (cannot be done from here)
1. Install the **release** arm64 APK on at least: one Android 8–10 phone, one Android 13+ phone (notification permission prompt), one small-screen phone. Check: launch (no white screen), sign-in, location permission denied/allowed, camera, check-in, check-out, app backgrounded during the flow, airplane mode at each step.
2. iOS: a release archive on a Mac, and the same pass on one notched iPhone and one small iPhone.
3. Arabic on a real device (font rendering, RTL back gestures).
