import 'dart:convert';

import '../../l10n/app_localizations.dart';

// Each validator takes the screen's [AppLocalizations] so its message is in
// the app's language. Without it (unit tests) the message is English.

String? emailValidator(String? email, [AppLocalizations? l10n]) {
  final value = email?.trim() ?? '';
  if (value.isEmpty) {
    return l10n?.validatorEmailRequired ?? 'Please enter your email';
  }
  if (!value.contains('@') || !value.contains('.')) {
    return l10n?.validatorEmailInvalid ?? 'Please enter a valid email';
  }
  return null;
}

String? passwordValidator(String? password, [AppLocalizations? l10n]) {
  final value = password ?? '';
  if (value.isEmpty) {
    return l10n?.validatorPasswordRequired ?? 'Please enter your password';
  }
  if (value.length < 6) {
    return l10n?.validatorPasswordShort ??
        'Password must be at least 6 characters';
  }
  return null;
}

/// Same rules as the `employee-accounts` Edge Function.
String? newPasswordValidator(String? password, [AppLocalizations? l10n]) {
  if (password == null || password.trim().isEmpty) {
    return l10n?.validatorNewPasswordRequired ?? 'Please enter a new password';
  }
  if (password.runes.length < 12) {
    return l10n?.validatorNewPasswordShort ??
        'Password must be at least 12 characters';
  }
  if (utf8.encode(password).length > 72) {
    return l10n?.validatorPasswordTooLong ?? 'Password is too long';
  }
  return null;
}

String? confirmPasswordValidator(
  String? confirmation,
  String password, [
  AppLocalizations? l10n,
]) {
  if (confirmation != password) {
    return l10n?.validatorPasswordsDontMatch ?? 'Passwords do not match';
  }
  return null;
}
