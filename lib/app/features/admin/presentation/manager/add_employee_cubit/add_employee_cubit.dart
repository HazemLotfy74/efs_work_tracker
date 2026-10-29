import 'dart:math' show Random;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/admin_errors.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'add_employee_state.dart';

/// Loads the schedules, then creates one employee account.
///
/// A retry of the same details reuses the same `request_id`, which the
/// Edge Function uses to return the account it already created instead
/// of creating a second one. Changed details get a new id.
class AddEmployeeCubit extends Cubit<AddEmployeeState> {
  AddEmployeeCubit(this._repository, {String Function()? newRequestId})
    : _newRequestId = newRequestId ?? _uuidV4,
      super(const AddEmployeeLoading());

  final AdminRepository _repository;
  final String Function() _newRequestId;

  NewEmployeeDraft? _lastDraft;
  String? _requestId;

  Future<void> load() async {
    emit(const AddEmployeeLoading());
    try {
      final schedules = await _repository.getSchedules();
      if (!isClosed) emit(AddEmployeeReady(schedules));
    } catch (_) {
      if (!isClosed) emit(const AddEmployeeLoadError());
    }
  }

  Future<void> submit(NewEmployeeDraft draft) async {
    final current = state;
    if (current is! AddEmployeeReady || current.submitting) return;
    final invalid = draft.invalidFields;
    if (invalid.isNotEmpty) {
      emit(current.copyWith(invalidFields: invalid, failure: null));
      return;
    }
    if (draft != _lastDraft) {
      _lastDraft = draft;
      _requestId = _newRequestId();
    }
    emit(
      current.copyWith(
        submitting: true,
        invalidFields: const {},
        failure: null,
      ),
    );
    try {
      final id = await _repository.createEmployee(
        draft,
        requestId: _requestId!,
      );
      if (!isClosed) emit(AddEmployeeCreated(id, draft));
    } catch (error) {
      if (isClosed) return;
      emit(
        current.copyWith(
          submitting: false,
          invalidFields: const {},
          failure: error is AdminFailure ? error : AdminFailure.unknown,
        ),
      );
    }
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
