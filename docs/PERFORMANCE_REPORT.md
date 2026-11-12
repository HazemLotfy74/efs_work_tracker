# Performance and APK size (2026-11-11)

All numbers are from real `flutter build` runs on this machine (Flutter 3.47.6, release).

## APK size

| Build | Size | Who gets it |
|---|---|---|
| `flutter build apk --release` (fat, 3 CPU types) | **65.4 MB** (68,548,147 B) | everyone, if you share one APK |
| `--split-per-abi` arm64-v8a | **22.9 MB** | almost every phone since ~2017 |
| `--split-per-abi` armeabi-v7a | 21.1 MB | old 32-bit phones |
| `--split-per-abi` x86_64 | 24.3 MB | emulators, Chromebooks |
| `flutter build appbundle` (.aab) | 62.2 MB upload | Google Play then delivers ≈ the per-CPU size above |

**Biggest win, no code change: stop distributing the fat APK.** On Google Play, upload the
`.aab`; for direct installs, send the arm64 APK (`app-arm64-v8a-release.apk`). A phone downloads
≈ 23 MB instead of 65 MB (−65%).

```
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

### What is inside the arm64 APK (`--analyze-size`)

| Part | Size |
|---|---|
| Native code (Flutter engine + compiled Dart) | 21 MB (Dart code ≈ 10 MB before compression: Flutter 3 MB, this app 668 KB, …) |
| Assets (fonts, SVGs) | 490 KB |
| Java/Kotlin (`classes.dex`, R8-shrunk) | 536 KB |

Nothing large is unused: images are SVGs, fonts are 4 Manrope + 4 Cairo weights, the icon
sources in `assets/icon/` are not bundled.

### Change made

| Change | arm64 APK |
|---|---|
| Before | 23.1 MB |
| Timezone data `latest.dart` → `latest_10y.dart` (same current rules incl. Cairo DST, ±5 years instead of the full history; data starts 2026) | **22.9 MB** |

Already in place: R8 minify + resource shrinking (release default, with keep rules for JNI
plugins — `android/app/proguard-rules.pro`), tree-shaken Material icons, selfies captured at
1080 px / quality 80.

Not done (would cost more than it saves): obfuscation (`--obfuscate --split-debug-info`) saves
little size and makes crash reports unreadable without the symbol files.

## Runtime performance

Measured items are in `admin_editing_reset_accounts_report.md` §5 (parallel reads, evidence
loaded only on the day page, images decoded at display size). No device profiling has been run;
no speed numbers are claimed.
