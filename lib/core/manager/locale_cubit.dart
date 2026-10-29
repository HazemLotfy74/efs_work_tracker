import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the chosen language is kept between launches.
abstract interface class LocaleStore {
  Future<String?> read();
  Future<void> write(String languageCode);
}

/// [LocaleStore] in the phone's app preferences. Only the language code
/// is stored, never account or attendance data.
class SharedPreferencesLocaleStore implements LocaleStore {
  static const _key = 'app_language';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String languageCode) async =>
      (await SharedPreferences.getInstance()).setString(_key, languageCode);
}

/// The app's language. Arabic until the user picks another one; the pick
/// survives restarts and doesn't touch the session.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._store) : super(fallback);

  final LocaleStore _store;

  static const fallback = Locale('ar');
  static const supported = [Locale('ar'), Locale('en')];

  /// Restores the saved language. A missing or unreadable one keeps
  /// [fallback].
  Future<void> load() async {
    try {
      final code = await _store.read();
      final saved = supported.where((l) => l.languageCode == code).firstOrNull;
      if (saved != null && !isClosed) emit(saved);
    } catch (_) {}
  }

  /// Switches at once; saving is best effort.
  Future<void> select(Locale locale) async {
    if (!supported.contains(locale)) return;
    emit(locale);
    try {
      await _store.write(locale.languageCode);
    } catch (_) {}
  }
}
