# shared_preferences_android 2.5.0 calls its Kotlin API from Dart through JNI
# (Pigeon JNI) and ships no keep rules. R8 can't see JNI calls, so in release it
# removed SharedPreferencesApiRegistrar.getAll and friends: Supabase.initialize
# then threw NoSuchMethodError before runApp and the app stayed on a white screen.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Kotlin classes that those JNI calls (and package:jni's suspend-function bridge)
# name directly. Renaming them breaks the lookups, so keep their names and members.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
