import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/request_errors.dart';
import '../../../domain/entities/expense_advance_request_entity.dart';
import '../../../domain/repositories/expense_advance_repository.dart';

part 'cash_request_submit_state.dart';

/// Sends one cash advance request from the new-request form.
class CashRequestSubmitCubit extends Cubit<CashRequestSubmitState> {
  CashRequestSubmitCubit(this._repository)
    : super(const CashRequestSubmitIdle());

  final ExpenseAdvanceRepository _repository;

  /// The draft whose last send ended without a clear answer.
  ExpenseAdvanceDraft? _unclear;

  Future<void> submit(ExpenseAdvanceDraft draft) async {
    // One send at a time: a second tap must not send a second request.
    if (state is CashRequestSubmitting || state is CashRequestSubmitted) {
      return;
    }
    emit(const CashRequestSubmitting());
    try {
      // The last send may have been saved after all: look before resending.
      if (_unclear == draft) {
        final saved = await _repository.findSubmitted(draft);
        if (saved != null) return _done(saved);
      }
      _done(await _repository.submit(draft));
    } catch (error) {
      final failure = error is RequestFailure ? error : RequestFailure.unknown;
      _unclear =
          failure == RequestFailure.outcomeUnknown ||
              failure == RequestFailure.network
          ? draft
          : null;
      if (!isClosed) emit(CashRequestSubmitFailed(failure));
    }
  }

  void _done(ExpenseAdvanceRequestEntity request) {
    _unclear = null;
    if (!isClosed) emit(CashRequestSubmitted(request));
  }
}
