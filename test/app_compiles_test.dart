import 'package:efs_work_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';

// lib/main.dart is not reached by any other test, so a bad merge there once
// passed every test while the app itself did not compile. Importing it makes
// `flutter test` fail when it doesn't.
void main() {
  test('the app entry point compiles', () {
    expect(main, isA<Function>());
    expect(WorkTrackApp, isNotNull);
  });
}
