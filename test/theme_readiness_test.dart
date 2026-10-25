import 'dart:io';

import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/home_view.dart';
import 'package:efs_work_tracker/core/theme/app_palette.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/theme/app_theme_colors.dart';
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

  group('light theme keeps the Figma values widgets used to hardcode', () {
    final theme = AppTheme.light;
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppThemeColors>()!;

    test('color scheme', () {
      expect(scheme.primary, AppPalette.green500);
      expect(scheme.primaryContainer, AppPalette.green50);
      expect(scheme.surface, AppPalette.white);
      expect(scheme.onSurface, AppPalette.green850);
      expect(scheme.onSurfaceVariant, AppPalette.neutral600);
      expect(scheme.secondary, AppPalette.green850);
      expect(scheme.onSecondary, AppPalette.white);
      expect(scheme.error, AppPalette.red500);
      expect(scheme.errorContainer, AppPalette.red50);
      expect(theme.scaffoldBackgroundColor, AppPalette.neutral100);
    });

    test('text and component colors', () {
      expect(theme.textTheme.bodyMedium?.color, AppPalette.green850);
      expect(theme.textTheme.bodySmall?.color, AppPalette.neutral600);
      expect(theme.navigationBarTheme.backgroundColor, AppPalette.white);
      expect(colors.headingText, AppPalette.green900);
      expect(colors.brandSurface, AppPalette.green900);
      expect(scheme.onPrimary, AppPalette.white);
      expect(theme.inputDecorationTheme.fillColor, AppPalette.neutral50);
      expect(theme.inputDecorationTheme.prefixIconColor, AppPalette.neutral300);
    });
  });

  test('both themes register the semantic color extension', () {
    expect(AppTheme.light.extension<AppThemeColors>(), isNotNull);
    expect(AppTheme.dark.extension<AppThemeColors>(), isNotNull);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });

  final screens = <String, Widget>{
    'home': const HomeView(),
    'attendance details': const AttendanceDetailsView(),
    'login': const LoginView(),
    'forgot password': const ForgotPasswordView(),
    'empty': const Scaffold(body: AppEmptyView()),
    'error': const Scaffold(body: AppErrorView()),
    'loading': const Scaffold(body: AppLoadingView()),
    'permission': const Scaffold(body: AppPermissionDeniedView()),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders with the dark theme', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
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
