import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/extensions/date_time_format.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../home/presentation/widgets/custom_status_container.dart';
import '../data/inbox_repository.dart';
import '../data/phone_alerts.dart';
import 'inbox_cubit.dart';

/// The Alerts tab: what happened to the user's requests and what waits for
/// their review. Built from the app's own cards, colors and state views.
///
/// A notification is marked read only when it is opened.
class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<InboxCubit>();
    final state = context.watch<InboxCubit>().state;
    final phoneAlerts = context.read<PhoneAlerts?>();
    final items = state.items;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alerts),
        actions: [
          if (phoneAlerts != null)
            IconButton(
              tooltip: l10n.enablePhoneAlerts,
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () => _enablePhoneAlerts(context, phoneAlerts),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: switch (items.isEmpty) {
            // Nothing to show yet: one full-screen state, still pullable.
            true => _Pullable(
              child: state.failed
                  ? AppErrorView(
                      title: l10n.inboxLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: cubit.refresh,
                    )
                  : state.loading
                  ? AppLoadingView(title: l10n.alerts, message: '')
                  : AppEmptyView(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.inboxEmpty,
                      message: l10n.inboxEmptyMessage,
                      actionLabel: null,
                    ),
            ),
            false => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: AppSpacing.lg,
              ),
              // One extra row above (progress / retry) and one below (more).
              itemCount: items.length + 2,
              separatorBuilder: (_, index) => SizedBox(
                height: index == 0 ? 0 : AppSpacing.md,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return _ListStatus(state: state, cubit: cubit);
                if (index == items.length + 1) {
                  return state.more
                      ? Center(
                          child: TextButton(
                            onPressed: state.loading
                                ? null
                                : () => cubit.refresh(more: true),
                            child: Text(l10n.inboxMore),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                final item = items[index - 1];
                return _NotificationCard(
                  key: ValueKey(item.id),
                  item: item,
                  onTap: () => _open(context, item),
                );
              },
            ),
          },
        ),
      ),
    );
  }

  Future<void> _enablePhoneAlerts(
    BuildContext context,
    PhoneAlerts phoneAlerts,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final enabled = await phoneAlerts.enable();
    showAppSnackBar(
      messenger,
      enabled ? l10n.phoneAlertsEnabled : l10n.phoneAlertsUnavailable,
      type: enabled ? AppMessageType.success : AppMessageType.warning,
    );
  }

  /// Marks the notification read and shows its request as the database
  /// lets this account see it now (it may have been reassigned or removed).
  void _open(BuildContext context, InboxNotification item) {
    final result = context.read<InboxCubit>().open(item);
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (context) => _RequestDialog(item: item, request: result),
    );
  }
}

/// Lets a full-screen state be pulled down to refresh.
class _Pullable extends StatelessWidget {
  const _Pullable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // The state views fill the height they are given.
      child: SizedBox(height: constraints.maxHeight, child: child),
    ),
  );
}

/// Above the list: a thin progress bar while refreshing, or why the refresh
/// failed with a way to retry. The list shown stays the last one loaded.
class _ListStatus extends StatelessWidget {
  const _ListStatus({required this.state, required this.cubit});

  final InboxState state;
  final InboxCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (!state.failed) return const SizedBox.shrink();
    final (background, foreground) = AppMessageType.error.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.inboxLoadFailed,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.inboxRetry,
              color: foreground,
              onPressed: cubit.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

extension on RequestKind {
  String label(BuildContext context) => switch (this) {
    RequestKind.expenseAdvance => context.l10n.adminCashRequest,
    RequestKind.overtime => context.l10n.overTimeRequests,
    RequestKind.correction => context.l10n.correctionRequest,
  };

  IconData get icon => switch (this) {
    RequestKind.expenseAdvance => Icons.payments_outlined,
    RequestKind.overtime => Icons.more_time_rounded,
    RequestKind.correction => Icons.edit_calendar_outlined,
  };
}

extension on InboxEvent {
  String label(BuildContext context) => switch (this) {
    InboxEvent.submitted => context.l10n.inboxSubmitted,
    InboxEvent.assigned => context.l10n.inboxAssigned,
    InboxEvent.approved => context.l10n.approved,
    InboxEvent.rejected => context.l10n.rejected,
  };

  /// A decision is green or red; something waiting for the user is amber.
  AppMessageType get type => switch (this) {
    InboxEvent.approved => AppMessageType.success,
    InboxEvent.rejected => AppMessageType.error,
    InboxEvent.submitted || InboxEvent.assigned => AppMessageType.warning,
  };
}

/// One notification: what it is about (icon and title), what happened, and
/// when. Unread ones have a tinted card, a bold title and a dot.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({super.key, required this.item, required this.onTap});

  final InboxNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final (tint, accent) = item.event.type.colorsOf(context);
    final unread = item.unread;
    final radius = BorderRadius.circular(AppRadius.lg);
    final when =
        '${item.createdAt.formatShortDate(context)} · ${item.createdAt.formatTime(context)}';
    return Semantics(
      button: true,
      label: unread ? context.l10n.inboxUnread : null,
      child: Material(
        color: unread
            ? Color.alphaBlend(
                colors.primary.withValues(alpha: 0.05),
                colors.surface,
              )
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: unread
                ? colors.primary.withValues(alpha: 0.35)
                : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(item.kind.icon, color: accent, size: 22),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        item.kind.label(context),
                        style: text.titleMedium?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.event.label(context),
                        style: text.bodyMedium?.copyWith(
                          color: unread ? accent : colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        when,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      key: const Key('unreadDot'),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The request behind a notification: its status, the employee's reason
/// and, once decided, the reviewer's reason for the decision.
class _RequestDialog extends StatelessWidget {
  const _RequestDialog({required this.item, required this.request});

  final InboxNotification item;
  final Future<Map<String, dynamic>?> request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Map<String, dynamic>?>(
      future: request,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final row = snapshot.data;
        final status = row?['status'];
        final close = AppDialogAction(
          label: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => Navigator.of(context).pop(),
        );
        if (!done) {
          return AppDialog(
            title: item.kind.label(context),
            content: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
            actions: [close],
          );
        }
        if (snapshot.hasError || row == null) {
          return AppDialog(
            title: item.kind.label(context),
            message: snapshot.hasError
                ? l10n.inboxLoadFailed
                : l10n.inboxRequestUnavailable,
            type: AppMessageType.warning,
            actions: [close],
          );
        }
        final approved = status == 'approved';
        final decided = approved || status == 'rejected';
        final reason = row['reason'];
        final decisionReason = row['review_note'];
        return AppDialog(
          title: item.kind.label(context),
          type: switch (status) {
            'approved' => AppMessageType.success,
            'rejected' => AppMessageType.error,
            _ => AppMessageType.warning,
          },
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Center(
                child: CustomStatusContainer(
                  tone: switch (status) {
                    'approved' => StatusTone.success,
                    'rejected' => StatusTone.error,
                    _ => StatusTone.warning,
                  },
                  text: switch (status) {
                    'approved' => l10n.approved,
                    'rejected' => l10n.rejected,
                    _ => l10n.pendingDecision,
                  },
                ),
              ),
              if (reason is String && reason.trim().isNotEmpty)
                _Labelled(label: l10n.correctionReason, text: reason),
              if (decided &&
                  decisionReason is String &&
                  decisionReason.trim().isNotEmpty)
                _Labelled(
                  key: const Key('inboxDecisionReason'),
                  label: approved
                      ? l10n.correctionApprovalReason
                      : l10n.correctionRejectionReason,
                  text: decisionReason,
                  type: approved ? AppMessageType.success : AppMessageType.error,
                ),
            ],
          ),
          actions: [close],
        );
      },
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({
    super.key,
    required this.label,
    required this.text,
    this.type = AppMessageType.info,
  });

  final String label;
  final String text;
  final AppMessageType type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = type.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(color: foreground),
          ),
          Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
