import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/location_cubit/location_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/check_in_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/attendance_session_page_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/location/location_view_page.dart';
import 'package:efs_work_tracker/core/errors/location_errors.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'location_fakes.dart';

void main() {
  late FakeLocationService gps;
  late FakeAddressService addresses;
  late LocationCubit cubit;

  setUp(() {
    gps = FakeLocationService(() async => testPosition());
    addresses = FakeAddressService();
    cubit = LocationCubit(locationService: gps, addressService: addresses);
    // Tests have no network, so map tiles fail to load; that is expected.
    FlutterError.onError = (details) {
      if (details.library != 'flutter_map') FlutterError.presentError(details);
    };
  });

  tearDown(() => cubit.close());

  /// Shows [child] in the app theme, with [cubit] provided above it.
  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: child),
        ),
      ),
    );
    await tester.pump(); // location result
    await tester.pump(); // address result
  }

  FilledButton button(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('loading: spinner and a disabled button', (tester) async {
    gps.result = () => Completer<Position>().future; // never finishes

    await show(tester, LocationViewPage(onContinue: () {}));

    expect(gps.requests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(button(tester).onPressed, isNull);
  });

  testWidgets('loaded: read-only map with the pin on the device position', (
    tester,
  ) async {
    var continued = false;

    await show(tester, LocationViewPage(onContinue: () => continued = true));

    const devicePoint = LatLng(30.0275, 31.4913);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final pins = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(map.options.initialCenter, devicePoint);
    expect(pins.markers.single.point, devicePoint);
    expect(map.options.interactionOptions.flags, InteractiveFlag.none);
    expect(
      find.ancestor(
        of: find.byType(FlutterMap),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsOneWidget,
    );

    expect(find.text('Location verified'), findsOneWidget);
    expect(find.textContaining('Accuracy · 8 meters'), findsOneWidget);
    expect(find.text('Current location'), findsOneWidget); // no address

    await tester.tap(find.text('Use this location'));
    expect(continued, isTrue);
    expect(gps.requests, 1); // rebuilds never ask GPS again
  });

  testWidgets('shows the street and city when found', (tester) async {
    addresses.result = () async => '90th Street, New Cairo 1, Cairo';

    await show(tester, LocationViewPage(onContinue: () {}));

    expect(find.text('90th Street, New Cairo 1, Cairo'), findsOneWidget);
    expect(find.text('Current location'), findsNothing);
  });

  testWidgets('permission denied: message and "Try again"', (tester) async {
    gps.result = () => Future.error(LocationFailure.permissionDenied);

    await show(tester, LocationViewPage(onContinue: () {}));

    expect(
      find.text('Location permission is needed to verify your attendance.'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsNothing);

    gps.result = () async => testPosition();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(gps.requests, 2);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('services off: "Open settings"', (tester) async {
    gps.result = () => Future.error(LocationFailure.serviceDisabled);

    await show(tester, LocationViewPage(onContinue: () {}));
    await tester.tap(find.text('Open settings'));

    expect(gps.locationSettingsOpened, 1);
  });

  group('step navigation', () {
    late PageController pages;

    setUp(() => pages = PageController());
    tearDown(() => pages.dispose());

    Future<void> showSteps(WidgetTester tester) => show(
      tester,
      Column(children: [AttendanceSessionPageView(pageController: pages)]),
    );

    testWidgets('Prepare: enabled primary button goes to Location', (
      tester,
    ) async {
      await showSteps(tester);

      // Enabled (it was disabled before, which made it grey).
      expect(button(tester).onPressed, isNotNull);
      final color =
          button(tester).style?.backgroundColor?.resolve({}) ??
          Theme.of(tester.element(find.byType(FilledButton)))
              .colorScheme
              .primary;
      expect(color, AppTheme.light.colorScheme.primary);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(pages.page, 1);
    });

    testWidgets('Location: "Use this location" goes to Selfie', (tester) async {
      await showSteps(tester);
      pages.jumpToPage(1);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();

      expect(pages.page, 2);
      expect(find.text('selfie'), findsOneWidget);
    });
  });

  // Regression: reading the locale inside BlocProvider's `create` threw
  // "Tried to listen to an InheritedWidget..." when the Location step opened.
  testWidgets('the real CheckInView opens the Location step', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CheckInView(),
      ),
    );

    // The step header shows two "Location" labels (cross-fade); tap one.
    await tester.tap(find.text('Location').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Verify Your Location'), findsOneWidget);
  });
}
