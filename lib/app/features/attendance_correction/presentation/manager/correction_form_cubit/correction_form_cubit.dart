import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/correction_errors.dart';
import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../domain/correction_rules.dart';
import '../../../domain/repositories/correction_repository.dart';

part 'correction_form_state.dart';

/// Sends one correction request for a closed attendance day.
class CorrectionFormCubit extends Cubit<CorrectionFormState> {
  CorrectionFormCubit(this._repository) : super(const CorrectionFormIdle());

  final CorrectionRepository _repository;

  /// Checks the times like the server does, then sends them.
  Future<void> submit(
    AttendanceSessionEntity session, {
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String reason,
  }) async {
    if (state is CorrectionFormSubmitting) return;
    final invalid = CorrectionRules.check(
      session,
      checkIn: checkIn,
      checkOut: checkOut,
      reason: reason,
    );
    if (invalid != null) {
      emit(CorrectionFormFailed(invalid));
      return;
    }
    emit(const CorrectionFormSubmitting());
    try {
      await _repository.submit(
        attendanceId: session.id,
        checkIn: checkIn!,
        checkOut: checkOut!,
        reason: reason,
      );
      if (!isClosed) emit(const CorrectionFormSubmitted());
    } catch (error) {
      if (isClosed) return;
      emit(
        CorrectionFormFailed(
          error is CorrectionFailure ? error : CorrectionFailure.unknown,
        ),
      );
    }
  }
}
