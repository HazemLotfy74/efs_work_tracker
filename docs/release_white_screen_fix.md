# Release APK white screen at startup (2026-11-02)

## Root cause (from the device log)

Release APK on a Redmi Note 8 Pro (wireless adb), app process log:

```
E/flutter: Unhandled Exception: PlatformException(... java.lang.NoSuchMethodError:
  no non-static method "Lio/flutter/plugins/sharedpreferences/SharedPreferencesApiRegistrar;
  .getAll(Ljava/lang/String;Ljava/util/List;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;"
```

- `shared_preferences_android` 2.5.0 (pulled in transitively) switched to **Pigeon JNI**: Dart
  calls the plugin's Kotlin methods directly through JNI, by class/method name and signature.
  The plugin ships **no R8 keep rules**.
- Release builds run R8. It can't see JNI calls, so it removed/renamed those methods and renamed
  the Kotlin types in their signatures (`Continuation` became `p6`).
- `main()` awaits `Supabase.initialize`, which reads the stored session through
  `shared_preferences`. That threw, so `runApp` was never called and Android kept showing the
  empty (white) window. Debug builds don't run R8, which is why only the release APK failed.

## Fix

- `android/app/proguard-rules.pro` (new): keep `io.flutter.plugins.sharedpreferences.**`, plus
  the Kotlin classes that these JNI calls and `package:jni`'s suspend-function bridge look up by
  name (`kotlin.Unit`, `Result`, `Result$Failure`, `coroutines.Continuation`,
  `coroutines.intrinsics.CoroutineSingletons`, `IntrinsicsKt`, `enums.EnumEntries`,
  `jvm.internal.DefaultConstructorMarker`). The list comes from every `kotlin/...` name in the Dart
  sources of `jni`, `jni_flutter`, `shared_preferences_android` and `path_provider_android`.
- `android/app/build.gradle.kts`: release uses `proguardFiles("proguard-rules.pro")`.
- No Dart code changed, no timeout or catch-all added.
- `path_provider_android` 2.3.1 also uses JNI, but only calls Android framework classes (it has
  no Kotlin classes of its own). `jni`/`jni_flutter` ship their own keep rules.

## Verification

| Check | Result |
|---|---|
| Original APK on the phone | process started, exception above ~80 ms after start, no `runApp` |
| Keep rule only for the plugin | next error: `ClassNotFoundException kotlin/coroutines/intrinsics/CoroutineSingletons` |
| Final APK on the phone (installed, launched with `am start`) | **no exception** in the app's log; `MainActivity` resumed |
| R8 mapping | `SharedPreferencesApiRegistrar.getAll(String, List, Continuation)` kept with its real signature |
| First frame on screen | **not seen by me**: the phone was locked with the screen off. Please unlock and open the app once |
| `flutter analyze` | 3 pre-existing infos in generated `lib/generated/assets.dart` |
| `flutter test` | 312 passed |
| `flutter build apk --release` | passed, 63.2 MB |

Build: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

If a future plugin update moves more code to JNI and the white screen comes back, run
`adb logcat --pid=$(adb shell pidof com.efs.efs_work_tracker)` and look for `NoSuchMethodError` /
`ClassNotFoundException`: that's the class to add here.
