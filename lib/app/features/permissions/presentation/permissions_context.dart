import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../domain/entities/permission_set.dart';
import 'manager/permissions_cubit.dart';

extension PermissionsContext on BuildContext {
  /// The signed-in account's permissions; rebuilds when they change.
  ///
  /// Only decides what is shown. Without a [PermissionsCubit] above (some
  /// widget tests) the role decides, as the database did before permissions.
  PermissionSet get permissions {
    try {
      return watch<PermissionsCubit>().state;
    } on ProviderNotFoundException {
      try {
        return switch (watch<AuthCubit>().state) {
          AuthSignedIn(:final user) => PermissionSet.fromRole(user),
          _ => PermissionSet.none,
        };
      } on ProviderNotFoundException {
        return PermissionSet.none;
      }
    }
  }
}
