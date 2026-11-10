import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/audit_entry_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'audit_history_state.dart';

/// The database's own change history for one employee, read-only.
class AuditHistoryCubit extends Cubit<AuditHistoryState> {
  AuditHistoryCubit(this._repository, this.employeeId)
    : super(const AuditHistoryLoading());

  final AdminRepository _repository;
  final String employeeId;

  Future<void> load() async {
    emit(const AuditHistoryLoading());
    try {
      // Names for "who": every account an admin can see.
      final (entries, employees) = await (
        _repository.getAuditHistory(employeeId),
        _repository.getEmployees(),
      ).wait;
      if (isClosed) return;
      emit(
        AuditHistoryLoaded(entries, {
          for (final employee in employees) employee.id: employee.fullName,
        }),
      );
    } catch (_) {
      if (!isClosed) emit(const AuditHistoryError());
    }
  }
}
