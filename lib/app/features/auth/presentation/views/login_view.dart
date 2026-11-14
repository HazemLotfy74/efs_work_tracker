import 'package:efs_work_tracker/app/features/auth/presentation/widgets/login_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../manager/auth_cubit/auth_cubit.dart';
import '../widgets/auth_failure_text.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    // A session taken over by a sign-in on another phone brings the user
    // here: the reason is already in the state when this screen opens, so a
    // listener alone would miss it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showNotice(context.read<AuthCubit>().state);
    });
  }

  /// Says, once, why the user is on this screen without having signed out.
  void _showNotice(AuthSessionState state) {
    if (state is! AuthSignedOut) return;
    final failure = state.linkFailure;
    if (failure == null) return;
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      failure.message(context.l10n),
      type: AppMessageType.error,
    );
    context.read<AuthCubit>().noticeShown();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthSessionState>(
      // A password-reset link that couldn't be used (expired, used, or
      // opened on another phone) arrives while this screen is open.
      listenWhen: (previous, current) =>
          current is AuthSignedOut && current.linkFailure != null,
      listener: (context, state) => _showNotice(state),
      child: Scaffold(body: LoginViewBody()),
    );
  }
}
