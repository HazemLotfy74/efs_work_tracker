import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/location_cubit/location_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_flow_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/attendance_flow_view_body.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/location/location_view_page.dart';
import 'package:efs_work_tracker/core/errors/location_errors.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/app_providers.dart';
import 'location_fakes.dart';

void main() {
  late FakeLocationService gps;
  late FakeAddressService addresses;
  late LocationCubit cubit;
  late AttendanceFlowCubit flow;

  setUp(() {
    gps = FakeLocationService(() async => testPosition());
    addresses = FakeAddressService();
    cubit = LocationCubit(locationService: gps, addressService: addresses);
    flow = AttendanceFlowCubit(AttendanceType.checkIn);
    // Tests have no network, so map tiles fail to load; that is expected.
    FlutterError.onError = (details) {
      if (details.library != 'flutter_map') FlutterError.presentError(details);
    };
  });

  tearDown(() {
    cubit.close();
    flow.close();
  });

  /// Shows [child] in the app theme, with both cubits provided above it and
  /// the location copied into the event like `AttendanceFlowView` does.
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
          body: withAppProviders(
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cubit),
                BlocProvider.value(value: flow),
              ],
              child: BlocListener<LocationCubit, LocationState>(
                listener: (context, state) => flow.setLocation(
                  state is LocationLoaded ? state.location : null,
                ),
                child: child,
              ),
            ),
          ),
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

    await show(tester, const LocationViewPage());

    expect(gps.requests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(button(tester).onPressed, isNull);
  });

  testWidgets('loaded: read-only map with the pin on the device position', (
    tester,
  ) async {
    flow.start(); // Prepare done, on the Location step

    await show(tester, const LocationViewPage());

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

    expect(flow.event.location?.accuracyMeters, 8); // stored
    await tester.tap(find.text('Use this location'));
    expect(flow.state.currentStep, 2);
    expect(gps.requests, 1); // rebuilds never ask GPS again
  });

  testWidgets('shows the street and city when found', (tester) async {
    addresses.result = () async => '90th Street, New Cairo 1, Cairo';

    await show(tester, const LocationViewPage());

    expect(find.text('90th Street, New Cairo 1, Cairo'), findsOneWidget);
    expect(find.text('Current location'), findsNothing);
  });

  testWidgets('permission denied: message and "Try again"', (tester) async {
    gps.result = () => Future.error(LocationFailure.permissionDenied);

    await show(tester, const LocationViewPage());

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

    await show(tester, const LocationViewPage());
    await tester.tap(find.text('Open settings'));

    expect(gps.locationSettingsOpened, 1);
  });

  group('step navigation', () {
    Future<void> showSteps(WidgetTester tester) =>
        show(tester, const AttendanceFlowViewBody());

    double? page(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller?.page;

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
      expect(page(tester), 1);
      expect(flow.event.time, isNotNull);
    });

    testWidgets('Location: "Use this location" goes to Selfie', (tester) async {
      await showSteps(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();

      expect(page(tester), 2);
      expect(find.text('Take a quick selfie'), findsOneWidget);
      // No selfie yet, so Selfie's Continue is disabled.
      expect(button(tester).onPressed, isNull);
    });

    testWidgets('locked steps in the stepper cannot be opened', (tester) async {
      await showSteps(tester);

      // The stepper has two "Review" labels (cross-fade); tap the visible one.
      await tester.tap(find.text('Review').hitTestable());
      await tester.pumpAndSettle();

      expect(page(tester), 0);
      expect(flow.state.currentStep, 0);
    });
  });

  // Regression: reading the locale inside BlocProvider's `create` threw
  // "Tried to listen to an InheritedWidget..." when the Location step opened.
  testWidgets('the real AttendanceFlowView opens the Location step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: withAppProviders(
          const AttendanceFlowView(type: AttendanceType.checkIn),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Verify Your Location'), findsOneWidget);
  });
}
