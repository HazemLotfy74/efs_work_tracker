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
  }) : fullName = fullName.trim(),
       username = username.trim().toLowerCase(),
       email = email.trim().toLowerCase(),
       employeeCode = employeeCode.trim().toUpperCase();

  final String fullName;
  final String username;
  final String email;
  final String employeeCode;
  final String? scheduleId;

  /// The first password; the employee must change it at first sign-in.
  final String password;

  static final _username = RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$');
  static final _employeeCode = RegExp(r'^[A-Z0-9][A-Z0-9_-]{1,49}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// The fields the Edge Function would refuse; empty when valid.
  Set<NewEmployeeField> get invalidFields => {
    if (fullName.isEmpty || fullName.length > 200) NewEmployeeField.fullName,
    if (!_username.hasMatch(username)) NewEmployeeField.username,
    if (email.length > 254 || !_email.hasMatch(email)) NewEmployeeField.email,
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
      other.password == password;

  @override
  int get hashCode => Object.hash(
    fullName,
    username,
    email,
    employeeCode,
    scheduleId,
    password,
  );
}
