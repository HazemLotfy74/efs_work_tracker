import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/correction_request_entity.dart';
import '../../../domain/repositories/correction_repository.dart';

part 'correction_requests_state.dart';

/// The signed-in employee's correction requests for one attendance day,
/// for its details page.
class CorrectionRequestsCubit extends Cubit<CorrectionRequestsState> {
  CorrectionRequestsCubit(this._repository, this.attendanceId)
    : super(const CorrectionRequestsLoading());

  final CorrectionRepository _repository;
  final String attendanceId;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads the requests; a failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! CorrectionRequestsLoaded) {
      emit(const CorrectionRequestsLoading());
    }
    try {
      final requests = await _repository.getForAttendance(attendanceId);
      if (isClosed || loadId != _loadId) return;
      emit(CorrectionRequestsLoaded(requests));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! CorrectionRequestsLoaded) {
        emit(const CorrectionRequestsError());
      }
    }
  }
}
