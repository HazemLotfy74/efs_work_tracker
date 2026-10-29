/// The only two roles in `profiles.role`.
enum UserRole {
  employee,
  admin;

  /// Unknown values fall back to [employee], the role with fewer permissions.
  static UserRole fromName(String? name) =>
      name == 'admin' ? UserRole.admin : UserRole.employee;
}

/// The signed-in account, built from the `get_account_status` RPC.
///
/// Phone and profile image are not here on purpose: the database has no
/// column for them.
class UserEntity {
  const UserEntity({
    required this.uID,
    required this.email,
    required this.fullName,
    required this.username,
    required this.employeeCode,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
  });

  final String uID;

  /// From Supabase Auth; `profiles` has no email column.
  final String email;
  final String fullName;
  final String username;
  final String employeeCode;
  final UserRole role;
  final bool isActive;

  /// True for new accounts and after a recovery link. Every feature is
  /// blocked by the database until the password is changed.
  final bool mustChangePassword;

  bool get isAdmin => role == UserRole.admin;

  /// Up to two letters for the avatar, e.g. "Mona Ali" → "MA".
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.where((part) => part.isNotEmpty).take(2);
    return letters.map((part) => part[0]).join().toUpperCase();
  }
}
