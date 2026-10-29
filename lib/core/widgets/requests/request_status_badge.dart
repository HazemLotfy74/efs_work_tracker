import 'package:flutter/material.dart';

import '../../enums/request_status.dart';
import '../../extensions/context_l10n.dart';
import '../../../app/features/home/presentation/widgets/custom_status_container.dart';

/// Status pill of an overtime or cash request.
class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (tone, text) = switch (status) {
      RequestStatus.pending => (StatusTone.warning, l10n.pendingApproval),
      RequestStatus.approved => (StatusTone.success, l10n.approved),
      RequestStatus.rejected => (StatusTone.error, l10n.rejected),
    };
    return CustomStatusContainer(tone: tone, text: text);
  }
}
