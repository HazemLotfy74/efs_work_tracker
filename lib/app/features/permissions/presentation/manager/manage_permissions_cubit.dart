import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../domain/entities/permission_set.dart';
import '../../domain/repositories/permission_repository.dart';

sealed class ManagePermissionsState {
  const ManagePermissionsState();
}

final class ManagePermissionsLoading extends ManagePermissionsState {
  const ManagePermissionsLoading();
}

final class ManagePermissionsError extends ManagePermissionsState {
  const ManagePermissionsError(this.failure);
  final AdminFailure failure;
}

final class ManagePermissionsLoaded extends ManagePermissionsState {
  const ManagePermissionsLoaded(
    this.entries,
    this.selected, {
    this.saving = false,
  });

  /// Every code, as the database reported it for this employee.
  final List<PermissionEntry> entries;

  /// The individual grants as edited on screen (not saved yet).
  final Set<String> selected;
  final bool saving;

  Set<String> get saved => {
    for (final entry in entries)
      if (entry.granted) entry.code,
  };

  Set<String> get added => selected.difference(saved);
  Set<String> get removed => saved.difference(selected);
  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty;
}

/// One employee's individual grants: edit on screen, review, save in one
/// call. The database decides what may change ([PermissionEntry.canChange]
/// only mirrors its rules).
class ManagePermissionsCubit extends Cubit<ManagePermissionsState> {
  ManagePermissionsCubit(this._repository, this.employeeId)
    : super(const ManagePermissionsLoading());

  final PermissionRepository _repository;
  final String employeeId;

  Future<void> load() async {
    emit(const ManagePermissionsLoading());
    try {
      final entries = await _repository.getFor(employeeId);
      if (isClosed) return;
      emit(
        ManagePermissionsLoaded(entries, {
          for (final entry in entries)
            if (entry.granted) entry.code,
        }),
      );
    } on AdminFailure catch (failure) {
      if (!isClosed) emit(ManagePermissionsError(failure));
    }
  }

  void toggle(String code, bool on) {
    final current = state;
    if (current is! ManagePermissionsLoaded || current.saving) return;
    final entry = current.entries.where((e) => e.code == code).firstOrNull;
    if (entry == null || !entry.canChange || entry.fromRole) return;
    emit(
      ManagePermissionsLoaded(current.entries, {
        ...current.selected.where((c) => c != code),
        if (on) code,
      }),
    );
  }

  /// Saves the edited grants; `null` on success (then reloads).
  Future<AdminFailure?> save() async {
    final current = state;
    if (current is! ManagePermissionsLoaded ||
        current.saving ||
        !current.hasChanges) {
      return null;
    }
    emit(
      ManagePermissionsLoaded(current.entries, current.selected, saving: true),
    );
    try {
      await _repository.setFor(employeeId, current.selected);
      await load();
      return null;
    } on AdminFailure catch (failure) {
      // Each flag is saved by its own call, so some may have changed: show
      // what the database holds now. If that can't be read either (offline),
      // keep the edit so it can be saved again.
      try {
        final entries = await _repository.getFor(employeeId);
        if (!isClosed) {
          emit(
            ManagePermissionsLoaded(entries, {
              for (final entry in entries)
                if (entry.granted) entry.code,
            }),
          );
        }
      } on AdminFailure {
        if (!isClosed) {
          emit(ManagePermissionsLoaded(current.entries, current.selected));
        }
      }
      return failure;
    }
  }
}
