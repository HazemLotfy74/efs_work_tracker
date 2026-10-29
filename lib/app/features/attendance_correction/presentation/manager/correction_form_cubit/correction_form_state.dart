part of 'correction_form_cubit.dart';

sealed class CorrectionFormState {
  const CorrectionFormState();
}

final class CorrectionFormIdle extends CorrectionFormState {
  const CorrectionFormIdle();
}

final class CorrectionFormSubmitting extends CorrectionFormState {
  const CorrectionFormSubmitting();
}

final class CorrectionFormSubmitted extends CorrectionFormState {
  const CorrectionFormSubmitted();
}

/// Nothing was sent ([failure] came from the form's own check), or the
/// server refused it, or its answer was lost ([CorrectionFailure.network]).
final class CorrectionFormFailed extends CorrectionFormState {
  const CorrectionFormFailed(this.failure);
  final CorrectionFailure failure;
}
