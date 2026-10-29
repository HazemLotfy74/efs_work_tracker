import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/manager/locale_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../attendance_session/presentation/widgets/shift_text.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';

/// The account from `get_account_status` (and the email from Auth). The
/// database has no phone or profile image, so neither is shown.
class ProfileViewBody extends StatelessWidget {
  const ProfileViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, UserEntity?>(
      (cubit) => switch (cubit.state) {
        AuthSignedIn(:final user) => user,
        _ => null,
      },
    );
    // The router only opens this tab when signed in.
    if (user == null) return const SizedBox.shrink();

    final attendance = context.watch<AttendanceSessionCubit>().state;
    final schedule = switch (attendance) {
      AttendanceSessionLoaded(:final shift?) => shift.rangeText(context),
      AttendanceSessionLoaded() => l10n.noShiftToday,
      _ => '--',
    };

    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        children: [
          Text(l10n.profile, style: context.textTheme.headlineSmall),
          CircleAvatar(
            radius: 40,
            backgroundColor: context.colors.secondary,
            child: Text(
              user.initials,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colors.onSecondary,
              ),
            ),
          ),
          Column(
            spacing: 4,
            children: [
              Text(user.fullName, style: context.textTheme.titleLarge),
              Text(
                user.isAdmin ? l10n.roleAdmin : l10n.roleEmployee,
                style: AppTextStyles.meta.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          CustomContainer(
            horizontalPadding: 20,
            verticalPadding: 20,
            borderWidth: 1,
            child: Column(
              children: [
                InfoRow(label: l10n.employeeCode, value: user.employeeCode),
                const Divider(height: 30),
                InfoRow(label: l10n.username, value: user.username),
                const Divider(height: 30),
                InfoRow(label: l10n.email, value: user.email),
                const Divider(height: 30),
                InfoRow(label: l10n.workSchedule, value: schedule),
              ],
            ),
          ),
          CustomContainer(
            borderWidth: 1,
            horizontalPadding: 20,
            verticalPadding: 12,
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.language, color: context.colors.primary),
                Expanded(
                  child: Text(
                    l10n.language,
                    style: context.textTheme.labelLarge,
                  ),
                ),
                SegmentedButton<Locale>(
                  key: const Key('languageSwitch'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: const Locale('ar'),
                      label: Text(l10n.languageArabic),
                    ),
                    ButtonSegment(
                      value: const Locale('en'),
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: {context.watch<LocaleCubit>().state},
                  onSelectionChanged: (selection) =>
                      context.read<LocaleCubit>().select(selection.single),
                ),
              ],
            ),
          ),
          // Only a convenience: RLS, review_request and the accounts
          // function check the admin role themselves.
          if (user.isAdmin)
            CustomContainer(
              key: const Key('adminDashboard'),
              borderWidth: 1,
              horizontalPadding: 20,
              verticalPadding: 16,
              onTap: () => context.push(AppRoutes.adminDashboard),
              child: Row(
                spacing: 10,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    color: context.colors.primary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.adminDashboard,
                      style: context.textTheme.labelLarge,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          AppPrimaryButton(
            bgColor: context.colors.error,
            onPressed: () => context.read<AuthCubit>().signOut(),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
