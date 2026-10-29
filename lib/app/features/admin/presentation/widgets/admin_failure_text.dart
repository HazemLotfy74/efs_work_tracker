import '../../../../../core/errors/admin_errors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/employee_entity.dart';

/// Message shown to the user for each [AdminFailure].
extension AdminFailureText on AdminFailure {
  String message(AppLocalizations l10n) => switch (this) {
    AdminFailure.notAllowed => l10n.adminNotAllowed,
    AdminFailure.accountConflict => l10n.adminAccountConflict,
    AdminFailure.invalidInput => l10n.adminInvalidInput,
    AdminFailure.outcomeUnknown => l10n.adminOutcomeUnknown,
    AdminFailure.tooManyRequests => l10n.adminTooManyRequests,
    AdminFailure.ownRequest => l10n.adminOwnRequest,
    AdminFailure.alreadyReviewed => l10n.adminAlreadyReviewed,
    AdminFailure.notFound => l10n.adminNotFound,
    AdminFailure.busy => l10n.adminBusy,
    AdminFailure.network => l10n.adminNetwork,
    AdminFailure.webOriginBlocked => l10n.adminWebOriginBlocked,
    AdminFailure.serviceUnavailable => l10n.adminServiceUnavailable,
    AdminFailure.unknown => l10n.adminUnknownError,
  };
}

/// Message for each invalid field of the add-employee form.
extension NewEmployeeFieldText on NewEmployeeField {
  String message(AppLocalizations l10n) => switch (this) {
    NewEmployeeField.fullName => l10n.adminInvalidFullName,
    NewEmployeeField.username => l10n.adminInvalidUsername,
    NewEmployeeField.email => l10n.adminInvalidEmail,
    NewEmployeeField.employeeCode => l10n.adminInvalidEmployeeCode,
    NewEmployeeField.schedule => l10n.adminInvalidSchedule,
    NewEmployeeField.password => l10n.adminInvalidPassword,
  };
}
