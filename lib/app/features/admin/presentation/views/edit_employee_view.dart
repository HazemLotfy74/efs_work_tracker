import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../auth/presentation/widgets/custom_text_form_field.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/admin_failure_text.dart';

/// Admin only: an employee account's name, username and employee code
/// (`admin_edit_employee_profile`), and a request to change its login
/// email (`admin_request_employee_email_change`). The email itself is never
/// changed from here: the employee confirms it through Supabase Auth.
///
/// Saving the details goes back to the employee page with `true`.
class EditEmployeeView extends StatefulWidget {
  const EditEmployeeView({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EditEmployeeView> createState() => _EditEmployeeViewState();
}

class _EditEmployeeViewState extends State<EditEmployeeView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _code = TextEditingController();
  final _newEmail = TextEditingController();

  LoginEmail? _email;
  AdminFailure? _loadFailure;
  bool _loading = true;
  bool _busy = false;

  AdminRepository get _repository => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _code.dispose();
    _newEmail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    try {
      final employee = await _repository.getEmployee(widget.employeeId);
      // The functions only accept employee accounts.
      if (employee == null || employee.isAdmin) throw AdminFailure.notFound;
      final email = await _repository.getLoginEmail(widget.employeeId);
      if (!mounted) return;
      _name.text = employee.fullName;
      _username.text = employee.username;
      _code.text = employee.employeeCode;
      setState(() {
        _email = email;
        _loading = false;
      });
    } on AdminFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadFailure = failure;
        _loading = false;
      });
    }
  }

  /// The three fields as the database will store and check them.
  NewEmployeeDraft get _draft => NewEmployeeDraft(
    fullName: _name.text,
    username: _username.text,
    employeeCode: _code.text,
    // Not edited here; valid values so only the three fields are judged.
    email: 'unused@example.com',
    scheduleId: 'unused',
    password: 'unused-password',
  );

  String? _validate(NewEmployeeField field) =>
      _draft.invalidFields.contains(field) ? field.message(context.l10n) : null;

  /// Runs one action with the buttons disabled; shows its result.
  Future<bool> _run(Future<void> Function() action, String done) async {
    if (_busy) return false;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    AdminFailure? failure;
    try {
      await action();
    } on AdminFailure catch (error) {
      failure = error;
    }
    if (mounted) setState(() => _busy = false);
    showAppSnackBar(
      messenger,
      failure?.message(l10n) ?? done,
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
    return failure == null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = _draft;
    final ok = await _run(
      () => _repository.editEmployee(
        widget.employeeId,
        fullName: draft.fullName,
        username: draft.username,
        employeeCode: draft.employeeCode,
      ),
      context.l10n.adminEmployeeSaved,
    );
    // Back to the employee page, which reloads on `true`.
    if (ok && mounted) await Navigator.of(context).maybePop(true);
  }

  Future<void> _requestEmail(String? email) async {
    final l10n = context.l10n;
    final current = _email?.email.toLowerCase();
    final text = email?.trim().toLowerCase();
    if (text != null &&
        (text == current ||
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text))) {
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        l10n.adminEmailInvalid,
        type: AppMessageType.error,
      );
      return;
    }
    final ok = await _run(
      () async {
        await _repository.requestEmailChange(widget.employeeId, text);
        final fresh = await _repository.getLoginEmail(widget.employeeId);
        if (mounted) setState(() => _email = fresh);
      },
      text == null
          ? l10n.adminEmailChangeCancelled
          : l10n.adminEmailChangeRequested,
    );
    if (ok) _newEmail.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _loadFailure;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: l10n.adminEditEmployee,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: _loading
                    ? AppLoadingView(title: l10n.adminEditEmployee, message: '')
                    : failure != null
                    ? AppErrorView(
                        title: l10n.adminLoadFailed,
                        message: failure.message(l10n),
                        onRetry: _load,
                      )
                    : _form(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final email = _email!;
    final pending = email.pendingEmail;
    final muted = AppTextStyles.meta.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return SingleChildScrollView(
      child: Column(
        spacing: 16,
        children: [
          CustomContainer(
            borderWidth: 1,
            horizontalPadding: 16,
            verticalPadding: 16,
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 14,
                children: [
                  CustomTextFormField(
                    key: const Key('editFullName'),
                    textEditingController: _name,
                    label: l10n.adminFullName,
                    hintTxt: l10n.adminFullName,
                    obscureText: false,
                    validator: (_) => _validate(NewEmployeeField.fullName),
                  ),
                  CustomTextFormField(
                    key: const Key('editUsername'),
                    textEditingController: _username,
                    label: l10n.username,
                    hintTxt: l10n.username,
                    obscureText: false,
                    validator: (_) => _validate(NewEmployeeField.username),
                  ),
                  CustomTextFormField(
                    key: const Key('editEmployeeCode'),
                    textEditingController: _code,
                    label: l10n.employeeCode,
                    hintTxt: l10n.employeeCode,
                    obscureText: false,
                    validator: (_) => _validate(NewEmployeeField.employeeCode),
                  ),
                  AppPrimaryButton(
                    key: const Key('saveEmployee'),
                    onPressed: _busy ? null : _save,
                    child: Text(l10n.adminSaveDetails),
                  ),
                ],
              ),
            ),
          ),
          CustomContainer(
            borderWidth: 1,
            horizontalPadding: 16,
            verticalPadding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                InfoRow(label: l10n.adminLoginEmail, value: email.email),
                Text(l10n.adminEmailChangeHint, style: muted),
                if (pending != null) ...[
                  Text(
                    l10n.adminEmailChangePending(pending),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.warning,
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('cancelEmailChange'),
                    onPressed: _busy ? null : () => _requestEmail(null),
                    child: Text(l10n.adminCancelEmailChange),
                  ),
                ] else ...[
                  CustomTextFormField(
                    key: const Key('newLoginEmail'),
                    textEditingController: _newEmail,
                    label: l10n.adminNewLoginEmail,
                    hintTxt: l10n.workEmail,
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  OutlinedButton(
                    key: const Key('requestEmailChange'),
                    onPressed: _busy
                        ? null
                        : () => _requestEmail(_newEmail.text),
                    child: Text(l10n.adminRequestEmailChange),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
