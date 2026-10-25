import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/attendance_event_entity.dart';
import '../../../domain/entities/attendance_type.dart';
import '../../../domain/entities/location_entity.dart';

part 'attendance_flow_state.dart';

/// Holds the [AttendanceEventEntity] being filled and which step is on
/// screen, for a check-in or a check-out (same steps, see [AttendanceType]).
///
/// The user can only move forward once the current step's data is stored,
/// and can only jump (stepper taps) to steps that are already unlocked.
class AttendanceFlowCubit extends Cubit<AttendanceFlowState> {
  AttendanceFlowCubit(AttendanceType type)
    : super(AttendanceFlowState(event: AttendanceEventEntity(type: type)));

  AttendanceEventEntity get event => state.event;

  /// Prepare step: stores the time and opens Location.
  void start() {
    _update(state.event.copyWith(time: DateTime.now().toUtc()));
    next();
  }

  /// Called whenever the location changes; `null` while it is (re)loading or
  /// failed, which locks the steps after Location again.
  void setLocation(LocationEntity? location) {
    _update(state.event.copyWith(location: () => location));
  }

  void setSelfie(String path) {
    _update(
      state.event.copyWith(
        selfiePath: path,
        selfieCapturedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void next() {
    if (!state.canContinue) return;
    emit(state.copyWith(currentStep: state.currentStep + 1));
  }

  void goToStep(int step) {
    if (step < 0 || step > state.event.unlockedStep) return;
    emit(state.copyWith(currentStep: step));
  }

  /// Keeps [AttendanceFlowState.currentStep] inside the unlocked steps.
  void _update(AttendanceEventEntity event) {
    final step = state.currentStep.clamp(0, event.unlockedStep);
    emit(AttendanceFlowState(event: event, currentStep: step));
  }
}
