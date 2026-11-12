import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/extensions/date_time_format.dart';
import '../data/inbox_repository.dart';
import '../data/phone_alerts.dart';
import 'inbox_cubit.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  String _kind(BuildContext context, RequestKind kind) => switch (kind) {
    RequestKind.expenseAdvance => context.l10n.adminCashRequest,
    RequestKind.overtime => context.l10n.overTimeRequests,
    RequestKind.correction => context.l10n.correctionRequest,
  };

  String _event(BuildContext context, InboxEvent event) => switch (event) {
    InboxEvent.submitted => context.l10n.inboxSubmitted,
    InboxEvent.assigned => context.l10n.inboxAssigned,
    InboxEvent.approved => context.l10n.approved,
    InboxEvent.rejected => context.l10n.rejected,
  };

  void _open(BuildContext context, InboxNotification item) {
    final result = context.read<InboxCubit>().open(item);
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: Text(_kind(context, item.kind)),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: result,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                widthFactor: 1,
                heightFactor: 1,
                child: CircularProgressIndicator(),
              );
            }
            final row = snapshot.data;
            if (snapshot.hasError) return Text(context.l10n.inboxLoadFailed);
            if (row == null) return Text(context.l10n.inboxRequestUnavailable);
            final status = switch (row['status']) {
              'approved' => context.l10n.approved,
              'rejected' => context.l10n.rejected,
              _ => context.l10n.pendingDecision,
            };
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status),
                  if (row['reason'] case final String reason) Text(reason),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InboxCubit>();
    final state = context.watch<InboxCubit>().state;
    final phoneAlerts = context.read<PhoneAlerts?>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.alerts),
        actions: [
          if (phoneAlerts != null)
            IconButton(
              tooltip: context.l10n.enablePhoneAlerts,
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () async {
                final enabled = await phoneAlerts.enable();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      enabled
                          ? context.l10n.phoneAlertsEnabled
                          : context.l10n.phoneAlertsUnavailable,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (state.loading) const LinearProgressIndicator(),
            if (state.failed)
              ListTile(
                title: Text(context.l10n.inboxLoadFailed),
                trailing: IconButton(
                  tooltip: context.l10n.inboxRetry,
                  onPressed: cubit.refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            if (!state.loading && !state.failed && state.items.isEmpty)
              ListTile(title: Text(context.l10n.inboxEmpty)),
            for (final item in state.items)
              ListTile(
                leading: Icon(
                  item.unread
                      ? Icons.mark_email_unread_outlined
                      : Icons.drafts_outlined,
                ),
                title: Text(_kind(context, item.kind)),
                subtitle: Text(
                  '${_event(context, item.event)} · ${item.createdAt.formatShortDate(context)} ${item.createdAt.formatTime(context)}',
                ),
                onTap: () => _open(context, item),
              ),
            if (state.more)
              TextButton(
                onPressed: state.loading
                    ? null
                    : () => cubit.refresh(more: true),
                child: Text(context.l10n.inboxMore),
              ),
          ],
        ),
      ),
    );
  }
}
