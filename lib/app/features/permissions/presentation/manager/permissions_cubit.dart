import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/permission_set.dart';
import '../../domain/repositories/permission_repository.dart';

/// The signed-in account's permissions, app-wide.
///
/// Admins get every admin-area code from their role, as the database
/// checks it. An employee's reviewer flags are read from their own
/// `profiles` row at sign-in and on [refresh] (app resume, opening the
/// assigned-reviews screen), so a grant or removal shows without signing
/// out. If that read fails, the role-based set is used: the database still
/// checks every request, so the app can only show too little, never do too
/// much. [enabled] off skips the read entirely.
class PermissionsCubit extends Cubit<PermissionSet> {
  PermissionsCubit(
    this._repository, {
    required this.enabled,
    PermissionSet initial = PermissionSet.none,
  }) : super(initial);

  final PermissionRepository _repository;
  final bool enabled;

  UserEntity? _user;
  int _loadId = 0;

  Future<void> userChanged(UserEntity? user) async {
    // Never keep the previous account's permissions, even briefly.
    if (user?.uID != _user?.uID && !isClosed) emit(PermissionSet.none);
    _user = user;
    await refresh();
  }

  Future<void> refresh() async {
    final user = _user;
    final loadId = ++_loadId;
    final fallback = PermissionSet.fromRole(user);
    // The reviewer flags only apply to employee accounts.
    if (user == null || !enabled || user.isAdmin) {
      emit(fallback);
      return;
    }
    try {
      final codes = await _repository.getMine();
      if (isClosed || loadId != _loadId) return;
      emit(PermissionSet(codes, isAdmin: user.isAdmin));
    } on AdminFailure {
      if (isClosed || loadId != _loadId) return;
      if (state == PermissionSet.none) emit(fallback);
    }
  }
}
