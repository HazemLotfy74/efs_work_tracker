import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/extensions/date_time_format.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/custom_container.dart';
import '../../../../home/presentation/widgets/custom_status_container.dart';
import '../../../domain/entities/attendance_event_entity.dart';

/// Selfie thumbnail with "Selfie ready" badge and the capture time.
class ReviewEvidenceCard extends StatelessWidget {
  const ReviewEvidenceCard({super.key, required this.event});

  final AttendanceEventEntity event;

  @override
  Widget build(BuildContext context) {
    final selfiePath = event.selfiePath;
    final capturedAt = event.selfieCapturedAt;

    return CustomContainer(
      horizontalPadding: 12,
      verticalPadding: 12,
      borderWidth: 1,
      borderRadius: 20,
      child: Row(
        spacing: 14,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 82,
              child: selfiePath != null
                  ? Image.file(File(selfiePath), fit: BoxFit.cover)
                  : ColoredBox(
                      color: context.colors.surfaceContainerLow,
                      child: Icon(
                        Icons.person_outline,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                CustomStatusContainer(
                  tone: StatusTone.success,
                  text: context.l10n.selfieReady,
                ),
                Text(
                  context.l10n.attendanceEvidence,
                  style: AppTextStyles.itemTitle,
                ),
                if (capturedAt != null)
                  Text(
                    context.l10n.capturedAt(capturedAt.formatTime(context)),
                    style: AppTextStyles.meta.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
