import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uID,
    required super.email,
    required super.fullName,
    required super.username,
    required super.employeeCode,
    required super.role,
    required super.isActive,
    required super.mustChangePassword,
  });

  /// [map] is the JSON returned by the `get_account_status` RPC. The role
  /// comes from `profiles`, never from the user-editable `user_metadata`.
  factory UserModel.fromAccountStatus(
    Map<String, dynamic> map, {
    required String email,
  }) {
    return UserModel(
      uID: map['id'] as String,
      email: email,
      fullName: map['full_name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      employeeCode: map['employee_code'] as String? ?? '',
      role: UserRole.fromName(map['role'] as String?),
      isActive: map['is_active'] as bool? ?? false,
      // Missing means "not ready": safer than letting the user in.
      mustChangePassword: map['must_change_password'] as bool? ?? true,
    );
  }
}
