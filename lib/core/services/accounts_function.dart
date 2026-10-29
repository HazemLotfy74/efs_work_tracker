import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/constants.dart';

/// Calls the `employee-accounts` Edge Function with the signed-in user's
/// own access token and returns its JSON answer. The function checks the
/// token against Auth and does privileged work with a server-side key; the
/// app never holds that key, and the admin's own session is not replaced.
///
/// Throws [AccountsFunctionException] when the function answers with an
/// error, any other exception when there is no answer.
typedef AccountsFunction = Future<Object?> Function(Map<String, dynamic> body);

class AccountsFunctionException implements Exception {
  const AccountsFunctionException(this.status, this.code);

  final int status;

  /// The `error` field, e.g. `forbidden`, `account_conflict`, or
  /// [unreachable] when no answer came back.
  final String? code;

  static const unreachable = 'unreachable';

  @override
  String toString() => 'AccountsFunctionException($status, $code)';
}

/// The real [AccountsFunction].
Future<Object?> invokeAccountsFunction(Map<String, dynamic> body) async {
  final session = Constants.supabase.auth.currentSession;
  if (session == null) {
    throw const AccountsFunctionException(401, 'unauthorized');
  }
  try {
    final response = await Constants.supabase.functions.invoke(
      Constants.accountsFunction,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: body,
    );
    return response.data;
  } on FunctionException catch (e) {
    // No HTTP answer at all. In a web browser this is what a refused CORS
    // preflight looks like: the function only accepts the one web origin
    // set in its ALLOWED_WEB_ORIGIN secret (phones send no Origin).
    if (e.status == 0) {
      log('employee-accounts unreachable: ${e.details.runtimeType}');
      throw const AccountsFunctionException(
        0,
        AccountsFunctionException.unreachable,
      );
    }
    final details = e.details;
    final code = details is Map ? details['error'] as String? : null;
    // Never log the body: it can hold a password.
    log('employee-accounts failed: status ${e.status}, code $code');
    throw AccountsFunctionException(e.status, code);
  }
}
