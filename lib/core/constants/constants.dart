import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Constants {
  static final String supabaseUrl = 'https://fotxyzooanysjthovpfz.supabase.co';
  static final String supabaseKey =
      'sb_publishable_UgI7glLOAnmcPAF0PENDvA_Co-OCBjK';
  static final SupabaseClient supabase = Supabase.instance.client;

  /// Edge Function for account actions such as changing the password.
  static const String accountsFunction = 'employee-accounts';

  /// Where a password-reset email link sends the user: this app, through
  /// the URL scheme in AndroidManifest.xml and Info.plist. Supabase only
  /// follows it when it is listed under Auth → URL Configuration →
  /// Redirect URLs.
  static const String passwordResetRedirect = 'efsworktracker://reset-password';

  /// Whether the Add Employee form offers the Employee / Admin role.
  /// Off until the backend accepts a role: today `employee-accounts`
  /// refuses the field and the account trigger always creates employees.
  /// See docs/proposal_roles_and_cash_guard.md.
  static const bool roleOnAccountCreation = false;

  /// Private bucket for check-in and check-out selfies.
  static const String attendanceEvidenceBucket = 'attendance-evidence';
}
