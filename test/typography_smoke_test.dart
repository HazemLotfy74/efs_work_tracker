import 'dart:io';

import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/history/presentation/views/history_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/profile/presentation/views/profile_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/home_view.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/widgets/states/app_empty_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_error_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_loading_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_permission_denied_view.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Manrope');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Manrope-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  final screens = <String, Widget>{
    'home': const HomeView(),
    'attendance details': const AttendanceDetailsView(id: 'none'),
    'history': const HistoryView(),
    'profile': const ProfileView(),
    'login': const LoginView(),
    'forgot password': const ForgotPasswordView(),
    'empty': const Scaffold(body: AppEmptyView()),
    'error': const Scaffold(body: AppErrorView()),
    'loading': const Scaffold(body: AppLoadingView()),
    'permission': const Scaffold(body: AppPermissionDeniedView()),
  };

  for (final scale in [1.0, 1.3]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders without overflow at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: withAppProviders(entry.value),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
