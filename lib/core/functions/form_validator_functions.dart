import 'dart:convert';

String? emailValidator(String? email) {
  if (email!.isEmpty) {
    return 'Please enter your email';
  }
  if (!email.contains('@')) {
    return 'Please enter a valid email';
  }
  if (!email.contains('.')) {
    return 'Please enter a valid email';
  }
  return null;
}

String? passwordValidator(String? password) {
  if (password!.isEmpty) {
    return 'Please enter your password';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

/// Same rules as the `employee-accounts` Edge Function.
String? newPasswordValidator(String? password) {
  if (password == null || password.trim().isEmpty) {
    return 'Please enter a new password';
  }
  if (password.runes.length < 12) {
    return 'Password must be at least 12 characters';
  }
  if (utf8.encode(password).length > 72) {
    return 'Password is too long';
  }
  return null;
}

String? confirmPasswordValidator(String? confirmation, String password) {
  if (confirmation != password) {
    return 'Passwords do not match';
  }
  return null;
}
