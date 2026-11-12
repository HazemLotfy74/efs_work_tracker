import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../../admin/data/repositories/supabase_admin_repository.dart';
import '../../domain/entities/permission_set.dart';
import '../../domain/repositories/permission_repository.dart';

/// [PermissionRepository] on the live database, unchanged:
/// - reads the `can_review_*` columns of `profiles` through its RLS policy
///   (your own row, or any row for an admin);
/// - changes them only through the `admin_set_*_reviewer_permission`
///   functions, which require an admin and only accept employee accounts.
class SupabasePermissionRepository implements PermissionRepository {
  SupabasePermissionRepository({
    required this._databaseServices,
    required this._currentUserId,
    this.timeout = const Duration(seconds: 20),
  });

  final DatabaseServices _databaseServices;
  final String? Function() _currentUserId;
  final Duration timeout;

  static final _columns = [
    'role',
    for (final flag in Permission.delegable.values) flag.column,
  ].join(', ');

  @override
  Future<Set<String>> getMine() async {
    final userId = _currentUserId() ?? (throw AdminFailure.notAllowed);
    final row = await _row(userId);
    return _parse(
      () => {
        for (final MapEntry(key: code, value: flag)
            in Permission.delegable.entries)
          if (row[flag.column] == true) code,
      },
    );
  }

  @override
  Future<List<PermissionEntry>> getFor(String userId) async {
    final row = await _row(userId);
    return _parse(() {
      // The functions only accept employee accounts; admins review through
      // their role and hold no flags.
      final isEmployee = row['role'] == 'employee';
      return [
        for (final MapEntry(key: code, value: flag)
            in Permission.delegable.entries)
          PermissionEntry(
            code: code,
            category: flag.category,
            sensitive: false,
            fromRole: false,
            granted: row[flag.column] == true,
            canChange: isEmployee,
          ),
      ];
    });
  }

  @override
  Future<void> setFor(String userId, Set<String> codes) async {
    final current = await getFor(userId);
    for (final entry in current) {
      final enabled = codes.contains(entry.code);
      if (!entry.canChange || entry.granted == enabled) continue;
      await _guard(
        () => _databaseServices.rpc(
          function: Permission.delegable[entry.code]!.function,
          params: {'p_employee_id': userId, 'p_enabled': enabled},
        ),
      );
    }
  }

  Future<Map> _row(String userId) async {
    final rows = await _guard(
      () => _databaseServices.getData(
        path: 'profiles',
        column: _columns,
        query: {'id': userId},
      ),
    );
    return _parse(
      () =>
          (rows as List).cast<Map>().firstOrNull ??
          (throw AdminFailure.notFound),
    );
  }

  Future<Object?> _guard(Future<dynamic> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('Permissions request failed: code ${e.code}');
      throw SupabaseAdminRepository.failureFor(e.code, e.message);
    } on Exception catch (e) {
      log('Permissions request failed: ${e.runtimeType}');
      throw AdminFailure.network;
    }
  }

  static T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on AdminFailure {
      rethrow;
    } catch (e) {
      log('Unreadable permissions: ${e.runtimeType}');
      throw AdminFailure.unknown;
    }
  }
}
