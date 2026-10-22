import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/location_cubit/location_cubit.dart';
import 'package:efs_work_tracker/core/errors/location_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'location_fakes.dart';

void main() {
  late FakeLocationService gps;
  late FakeAddressService addresses;
  late LocationCubit cubit;

  setUp(() {
    gps = FakeLocationService(() async => testPosition());
    addresses = FakeAddressService();
    cubit = LocationCubit(
      locationService: gps,
      addressService: addresses,
      languageCode: 'ar',
    );
  });

  tearDown(() => cubit.close());

  test('does nothing until the page asks', () {
    expect(cubit.state, isA<LocationInitial>());
    expect(gps.requests, 0);
  });

  test('loads the device position', () async {
    await cubit.fetchLocation();

    final state = cubit.state as LocationLoaded;
    expect(state.location.latitude, 30.0275);
    expect(state.location.longitude, 31.4913);
    expect(state.location.accuracyMeters, 8);
    expect(state.location.capturedAt, DateTime.utc(2026, 10, 22, 8, 7));
    expect(state.location.isMocked, isFalse);
    expect(state.location.address, isNull);
    // The getter the save step will use.
    expect(cubit.location, state.location);
  });

  test('no location before it is loaded', () {
    expect(cubit.location, isNull);
  });

  test('adds the address in the app language', () async {
    addresses.result = () async => 'شارع التسعين, القاهرة';

    await cubit.fetchLocation();

    expect(
      (cubit.state as LocationLoaded).location.address,
      'شارع التسعين, القاهرة',
    );
    expect(addresses.lastLanguage, 'ar');
  });

  for (final failure in LocationFailure.values) {
    test('$failure becomes an error state', () async {
      gps.result = () => Future.error(failure);

      await cubit.fetchLocation();

      expect((cubit.state as LocationError).failure, failure);
    });
  }

  test('any other exception becomes "unknown"', () async {
    gps.result = () => Future.error(StateError('plugin crashed'));

    await cubit.fetchLocation();

    expect((cubit.state as LocationError).failure, LocationFailure.unknown);
  });

  test('try again after an error', () async {
    gps.result = () => Future.error(LocationFailure.timeout);
    await cubit.fetchLocation();

    gps.result = () async => testPosition();
    await cubit.fetchLocation();

    expect(cubit.state, isA<LocationLoaded>());
    expect(gps.requests, 2);
  });

  test('ensureLocation only requests once', () async {
    cubit.ensureLocation();
    cubit.ensureLocation();
    await Future<void>.delayed(Duration.zero);
    cubit.ensureLocation();

    expect(gps.requests, 1);
  });

  test('a second tap while loading is ignored', () async {
    final pending = Completer<Position>();
    gps.result = () => pending.future;

    final first = cubit.fetchLocation();
    await cubit.fetchLocation();
    pending.complete(testPosition());
    await first;

    expect(gps.requests, 1);
  });

  test('closing while loading does not crash', () async {
    final pending = Completer<Position>();
    gps.result = () => pending.future;

    final request = cubit.fetchLocation();
    await cubit.close();
    pending.complete(testPosition());

    await expectLater(request, completes);
  });

  test('services off opens the location settings', () async {
    gps.result = () => Future.error(LocationFailure.serviceDisabled);
    await cubit.fetchLocation();

    await cubit.openSettings();

    expect(gps.locationSettingsOpened, 1);
  });

  test('permission blocked opens the app settings', () async {
    gps.result = () => Future.error(LocationFailure.permissionDeniedForever);
    await cubit.fetchLocation();

    await cubit.openSettings();

    expect(gps.appSettingsOpened, 1);
  });

  test('coming back from settings retries settings errors only', () async {
    gps.result = () => Future.error(LocationFailure.timeout);
    await cubit.fetchLocation();
    cubit.retryAfterSettings();
    expect(gps.requests, 1);

    gps.result = () => Future.error(LocationFailure.serviceDisabled);
    await cubit.fetchLocation();
    gps.result = () async => testPosition();
    cubit.retryAfterSettings();
    await Future<void>.delayed(Duration.zero);

    expect(gps.requests, 3);
    expect(cubit.state, isA<LocationLoaded>());
  });
}
