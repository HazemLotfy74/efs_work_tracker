import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../manager/correction_requests_cubit/correction_requests_cubit.dart';
import 'correction_request_details.dart';
import 'correction_text.dart';

/// On an attendance day's details: the latest correction request and its
/// status, and "Request correction" while the day needs review and no
/// request is pending.
class CorrectionSection extends StatelessWidget {
  const CorrectionSection({super.key, required this.session});

  final AttendanceSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CorrectionRequestsCubit, CorrectionRequestsState>(
      builder: (context, state) => switch (state) {
        CorrectionRequestsLoading() => const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        ),
        CorrectionRequestsError() => CustomContainer(
          borderWidth: 1,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.correctionLoadFailed,
                  style: context.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: context.read<CorrectionRequestsCubit>().load,
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
        CorrectionRequestsLoaded(:final latest, :final hasPending) => Column(
          spacing: 12,
          children: [
            if (latest != null)
              CustomContainer(
                borderWidth: 1,
                horizontalPadding: 16,
                verticalPadding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.correctionRequest,
                            style: context.textTheme.titleMedium,
                          ),
                        ),
                        CustomStatusContainer(
                          tone: latest.status.tone,
                          text: latest.status.label(l10n),
                        ),
                      ],
                    ),
                    CorrectionRequestDetails(
                      request: latest,
                      timezone: session.timezone,
                    ),
                    if (latest.isPending)
                      Text(
                        l10n.correctionPendingNote,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            if (session.needsReview && !hasPending)
              AppPrimaryButton(
                onPressed: () => _request(context),
                child: Text(l10n.requestCorrection),
              ),
          ],
        ),
      },
    );
  }

  Future<void> _request(BuildContext context) async {
    final cubit = context.read<CorrectionRequestsCubit>();
    await context.push<bool>(AppRoutes.attendanceCorrectionOf(session.id));
    // Reloaded however the form was left: a lost answer may still have
    // saved the request.
    if (!cubit.isClosed) await cubit.load();
  }
}
