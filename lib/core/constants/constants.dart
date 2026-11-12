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

  /// The reset link's target: the app on phones; on the web, the page's
  /// own origin (development or production, never a hard-coded localhost).
  /// Each value must be listed in Auth → URL Configuration → Redirect URLs.
  static String passwordResetRedirectFor({required bool isWeb, Uri? page}) {
    final current = page ?? Uri.base;
    final served = current.isScheme('http') || current.isScheme('https');
    return isWeb && served ? '${current.origin}/' : passwordResetRedirect;
  }

  /// The Add Employee form offers the Employee / Admin role and an optional
  /// phone number, and admin screens read `profiles.phone`. Needs
  /// supabase/migrations/20261102090100_account_role_and_phone.sql and
  /// employee-accounts version 2 (both live since 2026-11-02).
  static const bool accountRoleAndPhone = true;

  /// Admins can edit a closed day's check-in / check-out (Edit times on the
  /// admin day page). Needs `admin_correct_attendance` from
  /// supabase/migrations/20261102090000_admin_correct_attendance.sql (live
  /// since 2026-11-02).
  static const bool adminAttendanceCorrection = true;

  /// Permissions per person: an admin gives an employee the live
  /// database's reviewer flags (`profiles.can_review_*`) on the employee's
  /// Permissions page, then assigns them requests to decide. Off, admins
  /// can do everything and employees nothing extra. (The unapplied
  /// 20261111090000_permissions.sql is a different design and is not used.)
  static const bool dynamicPermissions = true;

  /// Whether selfies are named after the employee, e.g.
  /// `<uid>/Ahmed_Mohamed_EMP-125_check_in_20261101_060530_a81f2c0d.jpg`.
  /// Off until the bucket's upload policy (`attendance_selfie_upload`)
  /// accepts such names: today it only allows `<uid>/<uuid>.<ext>`, so a
  /// descriptive name would make every check-in fail.
  /// See docs/proposal_evidence_file_names.md.
  static const bool descriptiveEvidenceNames = false;

  /// Private bucket for check-in and check-out selfies.
  static const String attendanceEvidenceBucket = 'attendance-evidence';
}
