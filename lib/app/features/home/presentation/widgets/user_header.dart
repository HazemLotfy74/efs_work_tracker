import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/enums/day_part.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';

class UserHeader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;
    // Live time: the date and greeting change at midnight / noon by themselves.
    final now = context.watch<ClockCubit>().state;
    final user = context.select<AuthCubit, UserEntity?>(
      (cubit) => switch (cubit.state) {
        AuthSignedIn(:final user) => user,
        _ => null,
      },
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${now.formatWeekday(context)}  ${now.formatMonthDay(context)}'
                  .toUpperCase(),
              style: AppTextStyles.overline.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              DayPart.of(now).greeting(context.l10n),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              user?.fullName ?? '',
              style: textTheme.headlineSmall?.copyWith(
                color: context.appColors.headingText,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.surface),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 5),
                color: colorScheme.shadow.withAlpha(20),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              user?.initials ?? '',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
