import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push alerts on this phone (Android, Firebase Cloud Messaging).
///
/// The server sends them (`send-notification-push`), so they arrive while the
/// app is in the background or closed; Android shows them itself. This class
/// only registers the phone for the signed-in account and reacts to taps.
/// A phone is registered to one account and one session: signing in on another
/// phone moves the alerts there (the database drops this registration).
class PhoneAlerts {
  PhoneAlerts._(this._client, this._preferences, this._installation);

  final SupabaseClient _client;
  final SharedPreferences _preferences;
  final String _installation;
  static const _enabledKey = 'phone_alerts_enabled';

  String? _recipient;
  Future<void> _serial = Future.value();
  bool get enabled => _preferences.getBool(_enabledKey) ?? false;

  static Future<PhoneAlerts?> initialize(SupabaseClient client) async {
    // On unless a build turns it off: --dart-define=ENABLE_PHONE_ALERTS=false
    if (!const bool.fromEnvironment('ENABLE_PHONE_ALERTS', defaultValue: true)) {
      return null;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      final preferences = await SharedPreferences.getInstance();
      const key = 'phone_alerts_installation';
      final random = Random.secure();
      final installation =
          preferences.getString(key) ??
          List.generate(
            16,
            (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join();
      if (!await preferences.setString(key, installation)) return null;
      return PhoneAlerts._(client, preferences, installation);
    } catch (_) {
      return null;
    }
  }

  Future<void> listen({
    required VoidCallback onTap,
    required void Function(String? title, String? body) onForeground,
  }) async {
    // The HTTP v1 sender addresses FCM registration tokens.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => refresh(),
      onError: (Object _) {},
    );
    FirebaseMessaging.onMessage.listen((message) {
      // Android shows nothing by itself while the app is open.
      if (message.data['route'] == 'alerts') {
        onForeground(message.notification?.title, message.notification?.body);
      }
    });
    void handleTap(RemoteMessage message) {
      if (message.data['route'] == 'alerts') onTap();
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleTap);
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) handleTap(initial);
    } catch (_) {
      // Firebase startup must never interrupt the signed-in app.
    }
  }

  void userChanged(String? recipient) {
    if (_recipient == recipient) return;
    _recipient = recipient;
    if (recipient == null) return;
    // First sign-in on this phone: ask for the notification permission once.
    // Before this, nothing registered a phone unless the user found the bell
    // on the alerts screen, so no push was ever sent.
    if (_preferences.getBool(_enabledKey) == null) {
      enable();
    } else {
      refresh();
    }
  }

  Future<bool> enable() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        // Remember the answer: the bell on the alerts screen asks again.
        await _preferences.setBool(_enabledKey, false);
        return false;
      }
      await _enqueue(_register);
      return await _preferences.setBool(_enabledKey, true);
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    if (!enabled || _recipient == null) return;
    try {
      await _enqueue(_register);
    } catch (_) {
      // A later resume or token refresh retries registration.
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _serial.then((_) => action());
    _serial = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _register() async {
    final recipient = _recipient;
    if (recipient == null || _client.auth.currentUser?.id != recipient) {
      throw StateError('Push account unavailable');
    }
    final settings = await FirebaseMessaging.instance
        .getNotificationSettings()
        .timeout(const Duration(seconds: 5));
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (_recipient == recipient) await _unregister();
      throw StateError('Notification permission unavailable');
    }
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 5),
    );
    if (token == null) throw StateError('Push token unavailable');
    if (_recipient != recipient || _client.auth.currentUser?.id != recipient) {
      throw StateError('Push account changed');
    }
    await _client
        .rpc(
          'register_push_device',
          params: {'p_installation_id': _installation, 'p_token': token},
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<void> _unregister() async {
    await _client
        .rpc(
          'unregister_push_device',
          params: {'p_installation_id': _installation},
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<void> beforeSignOut() async {
    _recipient = null;
    if (!enabled) return;
    await _enqueue(() async {
      try {
        await _unregister();
      } catch (_) {
        // Server registration is also bound to the Supabase session.
      }
      try {
        // ignore: deprecated_member_use
        await FirebaseMessaging.instance.deleteToken().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {
        // A lost connection must not prevent sign-out.
      }
    });
  }
}
