import '../entities/permission_set.dart';

/// Reads and changes the permissions an employee can be given: the
/// `profiles.can_review_*` flags of the live database
/// ([Permission.delegable]). Every method throws an `AdminFailure`
/// (core/errors/admin_errors.dart).
abstract interface class PermissionRepository {
  /// The signed-in account's own flags, as codes.
  Future<Set<String>> getMine();

  /// Every delegable code as it applies to [userId].
  Future<List<PermissionEntry>> getFor(String userId);

  /// [userId]'s individual grants become exactly [codes]. Each flag is
  /// changed by its own admin function, so a failure part-way leaves the
  /// earlier ones changed: reload after an error.
  Future<void> setFor(String userId, Set<String> codes);
}
