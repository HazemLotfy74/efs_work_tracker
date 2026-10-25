part of 'attendance_flow_cubit.dart';

final class AttendanceFlowState {
  const AttendanceFlowState({required this.event, this.currentStep = 0});

  final AttendanceEventEntity event;

  /// The step on screen: 0 Prepare, 1 Location, 2 Selfie, 3 Review.
  final int currentStep;

  AttendanceType get type => event.type;

  /// `true` when the current step's data is captured.
  bool get canContinue => currentStep < event.unlockedStep;

  AttendanceFlowState copyWith({
    AttendanceEventEntity? event,
    int? currentStep,
  }) {
    return AttendanceFlowState(
      event: event ?? this.event,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
