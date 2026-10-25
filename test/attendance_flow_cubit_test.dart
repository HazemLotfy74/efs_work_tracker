import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/location_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AttendanceFlowCubit cubit;

  final location = LocationEntity(
    latitude: 30.0275,
    longitude: 31.4913,
    accuracyMeters: 8,
    capturedAt: DateTime.utc(2026, 10, 22, 8, 7),
  );

  setUp(() => cubit = AttendanceFlowCubit(AttendanceType.checkIn));
  tearDown(() => cubit.close());

  test('starts on Prepare with nothing captured', () {
    expect(cubit.state.currentStep, 0);
    expect(cubit.event.unlockedStep, 0);
    expect(cubit.event.isComplete, isFalse);
  });

  test('start stores the time and opens Location', () {
    cubit.start();

    expect(cubit.event.time, isNotNull);
    expect(cubit.state.currentStep, 1);
  });

  test('next does nothing until the current step is captured', () {
    cubit.start();

    cubit.next();
    expect(cubit.state.currentStep, 1); // no location yet

    cubit.setLocation(location);
    cubit.next();
    expect(cubit.state.currentStep, 2);

    cubit.next();
    expect(cubit.state.currentStep, 2); // no selfie yet

    cubit.setSelfie('/tmp/selfie.jpg');
    cubit.next();
    expect(cubit.state.currentStep, 3);
    expect(cubit.event.isComplete, isTrue);
    expect(cubit.event.selfieCapturedAt, isNotNull);
  });

  test('goToStep only opens unlocked steps', () {
    cubit.goToStep(3);
    expect(cubit.state.currentStep, 0);

    cubit.start();
    cubit.setLocation(location);
    cubit.goToStep(3);
    expect(cubit.state.currentStep, 1); // stayed on Location

    cubit.goToStep(2);
    expect(cubit.state.currentStep, 2);

    cubit.goToStep(0); // going back is always allowed
    expect(cubit.state.currentStep, 0);
  });

  test('losing the location locks the steps after it again', () {
    cubit.start();
    cubit.setLocation(location);
    expect(cubit.event.unlockedStep, 2);

    cubit.setLocation(null); // reloading or failed
    expect(cubit.event.location, isNull);
    expect(cubit.event.unlockedStep, 1);
    expect(cubit.state.canContinue, isFalse);
  });
}
