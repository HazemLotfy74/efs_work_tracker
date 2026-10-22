import 'package:efs_work_tracker/app/features/attendance_session/data/models/location_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/location_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entity = LocationEntity(
    latitude: 30.0275,
    longitude: 31.4913,
    accuracyMeters: 8.5,
    capturedAt: DateTime.utc(2026, 10, 22, 8, 7),
    address: '90th Street, New Cairo 1, Cairo',
  );

  test('toJson gives the Supabase columns', () {
    expect(LocationModel.fromEntity(entity).toJson(), {
      'latitude': 30.0275,
      'longitude': 31.4913,
      'accuracy_meters': 8.5,
      'captured_at': '2026-10-22T08:07:00.000Z',
      'address': '90th Street, New Cairo 1, Cairo',
      'is_mocked': false,
    });
  });

  test('fromJson reads a Supabase row back', () {
    final model = LocationModel.fromJson({
      'latitude': 30.0275,
      'longitude': 31, // Postgres may return a whole number as int
      'accuracy_meters': 8,
      'captured_at': '2026-10-22T08:07:00+00:00',
      'address': null,
      'is_mocked': true,
    });

    expect(model.longitude, 31.0);
    expect(model.accuracyMeters, 8.0);
    expect(model.capturedAt, DateTime.utc(2026, 10, 22, 8, 7));
    expect(model.address, isNull);
    expect(model.isMocked, isTrue);
  });

  test('toJson -> fromJson keeps the same location', () {
    final json = LocationModel.fromEntity(entity).toJson();
    expect(LocationModel.fromJson(json), entity);
  });

  test('copyWith adds the address and keeps the rest', () {
    final noAddress = LocationEntity(
      latitude: 1,
      longitude: 2,
      accuracyMeters: 3,
      capturedAt: DateTime.utc(2026),
    );

    final withAddress = noAddress.copyWith(address: 'Cairo');

    expect(withAddress.address, 'Cairo');
    expect(withAddress.latitude, 1);
    expect(withAddress, isNot(noAddress));
  });
}
