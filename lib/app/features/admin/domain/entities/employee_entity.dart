import 'dart:convert';

import '../../../auth/domain/entities/user_entity.dart';

/// One row of `profiles`, as an administrator sees it.
class EmployeeEntity {
  const EmployeeEntity({
    required this.id,
    required this.fullName,
    required this.username,
    required this.employeeCode,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.scheduleId,
    this.createdAt,
    this.phone,
  });

  final String id;
  final String fullName;
  final String username;
  final String employeeCode;
  final UserRole role;
  final bool isActive;

  /// A new account that hasn't signed in and changed its password yet.
  final bool mustChangePassword;
  final String scheduleId;

  /// When the account was created; `null` when not loaded.
  final DateTime? createdAt;

  /// International format (`+201012345678`); `null` when none was given
  /// (or the database has no phone column yet).
  final String? phone;

  bool get isAdmin => role == UserRole.admin;

  /// Case-insensitive match on name, username or employee code.
  bool matches(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return fullName.toLowerCase().contains(text) ||
        username.contains(text) ||
        employeeCode.toLowerCase().contains(text);
  }
}

/// One row of `work_schedules`.
class WorkScheduleOption {
  const WorkScheduleOption({
    required this.id,
    required this.name,
    required this.timezone,
  });

  final String id;
  final String name;

  /// IANA timezone, e.g. "Africa/Cairo".
  final String timezone;
}

/// Which field of [NewEmployeeDraft] is invalid.
enum NewEmployeeField {
  fullName,
  username,
  email,
  phone,
  employeeCode,
  schedule,
  password,
}

/// A new employee account as the admin filled it in, normalized the way
/// the `employee-accounts` Edge Function normalizes it.
class NewEmployeeDraft {
  NewEmployeeDraft({
    required String fullName,
    required String username,
    required String email,
    required String employeeCode,
    required this.scheduleId,
    required this.password,
    this.role = UserRole.employee,
    String phone = '',
  }) : fullName = fullName.trim(),
       username = username.trim().toLowerCase(),
       email = email.trim().toLowerCase(),
       employeeCode = employeeCode.trim().toUpperCase(),
       phone = normalizePhone(phone);

  final String fullName;
  final String username;
  final String email;
  final String employeeCode;
  final String? scheduleId;

  /// The first password; the employee must change it at first sign-in.
  final String password;

  /// Employee unless the admin chose Admin (only when the backend accepts
  /// a role, see `Constants.accountRoleAndPhone`).
  final UserRole role;

  /// Optional; `null` when left empty. Spaces, dashes and brackets are
  /// dropped, so `+20 101 234-5678` is sent as `+201012345678`.
  final String? phone;

  static final _username = RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$');
  static final _employeeCode = RegExp(r'^[A-Z0-9][A-Z0-9_-]{1,49}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// The database's format (`private.normalize_phone`): `+`, a non-zero
  /// country digit, then 7–14 digits.
  static final phoneFormat = RegExp(r'^\+[1-9][0-9]{7,14}$');

  static String? normalizePhone(String value) {
    final compact = value.replaceAll(RegExp(r'[\s\-()]'), '');
    return compact.isEmpty ? null : compact;
  }

  /// The fields the Edge Function would refuse; empty when valid.
  Set<NewEmployeeField> get invalidFields => {
    if (fullName.isEmpty || fullName.length > 200) NewEmployeeField.fullName,
    if (!_username.hasMatch(username)) NewEmployeeField.username,
    if (email.length > 254 || !_email.hasMatch(email)) NewEmployeeField.email,
    if (phone case final phone? when !phoneFormat.hasMatch(phone))
      NewEmployeeField.phone,
    if (!_employeeCode.hasMatch(employeeCode)) NewEmployeeField.employeeCode,
    if (scheduleId == null) NewEmployeeField.schedule,
    if (password.runes.length < 12 ||
        password.trim().isEmpty ||
        utf8.encode(password).length > 72)
      NewEmployeeField.password,
  };

  @override
  bool operator ==(Object other) =>
      other is NewEmployeeDraft &&
      other.fullName == fullName &&
      other.username == username &&
      other.email == email &&
      other.employeeCode == employeeCode &&
      other.scheduleId == scheduleId &&
      other.password == password &&
      other.role == role &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(
    fullName,
    username,
    email,
    employeeCode,
    scheduleId,
    password,
    role,
    phone,
  );
}
