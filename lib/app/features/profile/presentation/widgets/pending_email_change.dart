import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_failure_text.dart';

/// Shown on the profile while an admin's request to change this employee's
/// login email is open. The employee starts Supabase Auth's own change,
/// which emails a confirmation link; the database only accepts the address
/// the admin asked for. Nothing is shown when there is no request.
class PendingEmailChange extends StatefulWidget {
  const PendingEmailChange({super.key});

  @override
  State<PendingEmailChange> createState() => _PendingEmailChangeState();
}

class _PendingEmailChangeState extends State<PendingEmailChange> {
  late final Future<String?> _pending = context
      .read<AuthCubit>()
      .pendingLoginEmail();
  bool _sending = false;
  bool _sent = false;

  Future<void> _confirm(String email) async {
    if (_sending) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AuthCubit>();
    setState(() => _sending = true);
    String? error;
    try {
      await cubit.confirmLoginEmail(email);
    } catch (failure) {
      error = authErrorMessage(failure, l10n);
    }
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = error == null;
      });
    }
    showAppSnackBar(
      messenger,
      error ?? l10n.emailChangeSent(email),
      type: error == null ? AppMessageType.success : AppMessageType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<String?>(
      future: _pending,
      builder: (context, snapshot) {
        final email = snapshot.data;
        if (email == null) return const SizedBox.shrink();
        return CustomContainer(
          key: const Key('pendingEmailChange'),
          borderWidth: 1,
          horizontalPadding: 20,
          verticalPadding: 16,
          containerColor: context.appColors.warningContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                _sent
                    ? l10n.emailChangeSent(email)
                    : l10n.emailChangeProfileNote(email),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.warning,
                ),
              ),
              if (!_sent)
                OutlinedButton(
                  key: const Key('confirmEmailChange'),
                  onPressed: _sending ? null : () => _confirm(email),
                  child: Text(l10n.emailChangeConfirm),
                ),
            ],
          ),
        );
      },
    );
  }
}
