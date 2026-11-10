import 'package:efs_work_tracker/app/features/auth/presentation/widgets/login_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../manager/auth_cubit/auth_cubit.dart';
import '../widgets/auth_failure_text.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthSessionState>(
      // A password-reset link that couldn't be used (expired, used, or
      // opened on another phone) lands here; say why, once.
      listenWhen: (previous, current) =>
          current is AuthSignedOut && current.linkFailure != null,
      listener: (context, state) {
        final failure = (state as AuthSignedOut).linkFailure!;
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          failure.message(context.l10n),
          type: AppMessageType.error,
        );
      },
      child: Scaffold(body: LoginViewBody()),
    );
  }
}
