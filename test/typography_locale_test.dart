import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('locale fonts', () {
    test('English uses Manrope with Cairo for Arabic glyphs', () {
      final theme = AppTheme.lightFor(const Locale('en'));
      final style = theme.textTheme.headlineMedium!;
      expect(style.fontFamily, 'Manrope');
      expect(style.fontFamilyFallback, ['Cairo']);
      expect(style.letterSpacing, -0.7);
    });

    test('Arabic uses Cairo everywhere, without letter spacing', () {
      final theme = AppTheme.lightFor(const Locale('ar'));
      for (final style in [
        theme.textTheme.displaySmall!,
        theme.textTheme.headlineMedium!,
        theme.textTheme.bodyMedium!,
        theme.textTheme.labelLarge!,
        theme.appBarTheme.titleTextStyle!,
      ]) {
        expect(style.fontFamily, 'Cairo');
        expect(style.letterSpacing ?? 0, 0);
      }
    });

    testWidgets('direct roles inherit the locale font', (tester) async {
      late TextStyle effective;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightFor(const Locale('ar')),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  final style = context.tracked(AppTextStyles.overline);
                  effective = DefaultTextStyle.of(context).style.merge(style);
                  return Text('مرحبا', style: style);
                },
              ),
            ),
          ),
        ),
      );
      expect(effective.fontFamily, 'Cairo');
      expect(effective.letterSpacing, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tracked keeps letter spacing in left-to-right text', (
      tester,
    ) async {
      late TextStyle style;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              style = context.tracked(AppTextStyles.overline);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(style.letterSpacing, 1.2);
    });
  });
}
