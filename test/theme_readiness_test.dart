import 'dart:io';

import 'package:efs_work_tracker/app/features/home/presentation/views/home_view.dart';
import 'package:efs_work_tracker/core/theme/app_colors.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/theme/app_theme_colors.dart';
import 'package:efs_work_tracker/core/widgets/states/app_empty_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_error_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_loading_view.dart';
import 'package:efs_work_tracker/core/widgets/states/app_permission_denied_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(scheme.primary, AppColors.primary);
      expect(scheme.primaryContainer, AppColors.primarySoft);
      expect(scheme.surface, AppColors.white);
      expect(scheme.onSurface, AppColors.textPrimary);
      expect(scheme.onSurfaceVariant, AppColors.textSecondary);
      expect(scheme.secondary, AppColors.textPrimary);
      expect(scheme.onSecondary, AppColors.white);
      expect(scheme.error, AppColors.error);
      expect(scheme.errorContainer, AppColors.errorSoft);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('text and component colors', () {
      expect(theme.textTheme.bodyMedium?.color, AppColors.textPrimary);
      expect(theme.textTheme.bodySmall?.color, AppColors.textSecondary);
      expect(theme.navigationBarTheme.backgroundColor, AppColors.white);
      expect(colors.textHeading, AppColors.textHeading);
      expect(colors.attendanceCard, AppColors.attendanceCard);
    });
  });

  test('both themes register the semantic color extension', () {
    expect(AppTheme.light.extension<AppThemeColors>(), isNotNull);
    expect(AppTheme.dark.extension<AppThemeColors>(), isNotNull);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });

  final screens = <String, Widget>{
    'home': const HomeView(),
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
        MaterialApp(theme: AppTheme.dark, home: entry.value),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
