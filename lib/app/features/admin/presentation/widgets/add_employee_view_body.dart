import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../domain/entities/employee_entity.dart';
import '../manager/add_employee_cubit/add_employee_cubit.dart';
import 'admin_failure_text.dart';

class AddEmployeeViewBody extends StatelessWidget {
  const AddEmployeeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 16,
      children: [
        customAppBar(
          context: context,
          title: l10n.adminAddEmployee,
          leading: CustomBackButton(),
        ),
        Expanded(
          child: BlocBuilder<AddEmployeeCubit, AddEmployeeState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType ||
                current is AddEmployeeReady,
            builder: (context, state) => switch (state) {
              AddEmployeeLoading() => AppLoadingView(
                title: l10n.adminAddEmployee,
                message: '',
              ),
              AddEmployeeLoadError() => AppErrorView(
                title: l10n.adminSchedulesLoadFailed,
                message: l10n.authNetworkError,
                onRetry: context.read<AddEmployeeCubit>().load,
              ),
              AddEmployeeReady() => _Form(state: state),
              AddEmployeeCreated(:final draft) => _Created(draft: draft),
            },
          ),
        ),
      ],
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state});

  final AddEmployeeReady state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  late String? _scheduleId = widget.state.schedules.length == 1
      ? widget.state.schedules.single.id
      : null;
  bool _obscure = true;

  @override
  void dispose() {
    for (final controller in [_fullName, _username, _email, _code, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AddEmployeeCubit>().submit(
      NewEmployeeDraft(
        fullName: _fullName.text,
        username: _username.text,
        email: _email.text,
        employeeCode: _code.text,
        scheduleId: _scheduleId,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final invalid = state.invalidFields;
    final enabled = !state.submitting;
    String? error(NewEmployeeField field) =>
        invalid.contains(field) ? field.message(l10n) : null;

    Widget field(
      String key,
      String label,
      TextEditingController controller,
      NewEmployeeField kind, {
      TextInputType? keyboard,
      bool obscure = false,
      Widget? suffix,
      String? helper,
    }) => TextField(
      key: Key(key),
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        errorText: error(kind),
        helperText: helper,
        helperMaxLines: 2,
        errorMaxLines: 3,
        suffixIcon: suffix,
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          field(
            'fullName',
            l10n.adminFullName,
            _fullName,
            NewEmployeeField.fullName,
          ),
          field(
            'username',
            l10n.username,
            _username,
            NewEmployeeField.username,
          ),
          field(
            'email',
            l10n.email,
            _email,
            NewEmployeeField.email,
            keyboard: TextInputType.emailAddress,
          ),
          field(
            'employeeCode',
            l10n.employeeCode,
            _code,
            NewEmployeeField.employeeCode,
          ),
          DropdownButtonFormField<String>(
            key: const Key('schedule'),
            initialValue: _scheduleId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.workSchedule,
              errorText: error(NewEmployeeField.schedule),
            ),
            items: [
              for (final schedule in state.schedules)
                DropdownMenuItem(
                  value: schedule.id,
                  child: Text(
                    '${schedule.name} (${schedule.timezone})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled
                ? (value) => setState(() => _scheduleId = value)
                : null,
          ),
          field(
            'password',
            l10n.adminInitialPassword,
            _password,
            NewEmployeeField.password,
            obscure: _obscure,
            helper: l10n.adminInitialPasswordHint,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          if (state.failure case final failure?)
            Text(
              failure.message(l10n),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
          AppPrimaryButton(
            onPressed: enabled ? _submit : null,
            child: state.submitting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.adminCreateAccount),
          ),
        ],
      ),
    );
  }
}

class _Created extends StatelessWidget {
  const _Created({required this.draft});

  final NewEmployeeDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 16,
      children: [
        CustomContainer(
          borderWidth: 1,
          horizontalPadding: 16,
          verticalPadding: 16,
          containerColor: context.colors.primaryContainer,
          child: Row(
            spacing: 10,
            children: [
              Icon(Icons.check_circle_outline, color: context.colors.primary),
              Expanded(
                child: Text(
                  l10n.adminAccountCreated(draft.fullName),
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        AppPrimaryButton(
          onPressed: () => context.pop(),
          child: Text(l10n.adminDashboard),
        ),
        TextButton(
          onPressed: context.read<AddEmployeeCubit>().load,
          child: Text(l10n.adminAddAnother),
        ),
      ],
    );
  }
}
