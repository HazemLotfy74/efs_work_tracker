part of 'add_employee_cubit.dart';

sealed class AddEmployeeState {
  const AddEmployeeState();
}

final class AddEmployeeLoading extends AddEmployeeState {
  const AddEmployeeLoading();
}

final class AddEmployeeLoadError extends AddEmployeeState {
  const AddEmployeeLoadError();
}

/// The form, while it is filled in and sent.
final class AddEmployeeReady extends AddEmployeeState {
  const AddEmployeeReady(
    this.schedules, {
    this.submitting = false,
    this.invalidFields = const {},
    this.failure,
  });

  final List<WorkScheduleOption> schedules;
  final bool submitting;

  /// Found before sending; nothing was sent.
  final Set<NewEmployeeField> invalidFields;

  /// The server's answer to the last attempt.
  final AdminFailure? failure;

  AddEmployeeReady copyWith({
    bool? submitting,
    Set<NewEmployeeField>? invalidFields,
    required AdminFailure? failure,
  }) => AddEmployeeReady(
    schedules,
    submitting: submitting ?? this.submitting,
    invalidFields: invalidFields ?? this.invalidFields,
    failure: failure,
  );
}

final class AddEmployeeCreated extends AddEmployeeState {
  const AddEmployeeCreated(this.id, this.draft);
  final String id;
  final NewEmployeeDraft draft;
}
