import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/enums/request_status.dart';
import '../../../../../../core/errors/request_errors.dart';
import '../../../domain/entities/expense_advance_request_entity.dart';
import '../../../domain/repositories/expense_advance_repository.dart';

part 'cash_requests_state.dart';

/// The signed-in employee's cash advance requests, filtered by status.
class CashRequestsCubit extends Cubit<CashRequestsState> {
  CashRequestsCubit(this._repository) : super(const CashRequestsLoading());

  final ExpenseAdvanceRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads the requests; a failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! CashRequestsLoaded) {
      emit(CashRequestsLoading(filter: state.filter));
    }
    try {
      final requests = await _repository.getRequests();
      if (isClosed || loadId != _loadId) return;
      emit(CashRequestsLoaded(requests, filter: state.filter));
    } catch (error) {
      if (isClosed || loadId != _loadId) return;
      if (state is! CashRequestsLoaded) {
        emit(
          CashRequestsError(
            error is RequestFailure ? error : RequestFailure.unknown,
            filter: state.filter,
          ),
        );
      }
    }
  }

  /// Shows only requests with [status]; `null` shows all.
  void filterBy(RequestStatus? status) {
    emit(switch (state) {
      CashRequestsLoading() => CashRequestsLoading(filter: status),
      CashRequestsLoaded(:final requests) => CashRequestsLoaded(
        requests,
        filter: status,
      ),
      CashRequestsError(:final failure) => CashRequestsError(
        failure,
        filter: status,
      ),
    });
  }
}
