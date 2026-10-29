import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/request_failure_text.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/presentation/widgets/custom_app_header.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/custom_text_form_field.dart';
import '../../../../../core/functions/request_validators.dart';
import '../../domain/entities/expense_advance_request_entity.dart';
import '../manager/cash_request_submit_cubit/cash_request_submit_cubit.dart';
import 'money_text.dart';

class NewCashRequestViewBody extends StatefulWidget {
  const NewCashRequestViewBody({super.key});

  @override
  State<NewCashRequestViewBody> createState() => _NewCashRequestViewBodyState();
}

class _NewCashRequestViewBodyState extends State<NewCashRequestViewBody> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CashRequestSubmitCubit>().submit(
      ExpenseAdvanceDraft(
        amount: parseAmount(_amount.text)!,
        reason: _reason.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthCubit>().state;
    final employee = auth is AuthSignedIn ? auth.user.fullName : '';
    return BlocConsumer<CashRequestSubmitCubit, CashRequestSubmitState>(
      listener: (context, state) {
        if (state is CashRequestSubmitted) context.pop(state.request);
      },
      builder: (context, state) {
        final sending =
            state is CashRequestSubmitting || state is CashRequestSubmitted;
        return SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                CustomAppHeader(title: l10n.newCashRequest),
                CustomContainer(
                  containerColor: context.colors.primaryContainer,
                  borderWidth: 1,
                  child: Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.privacy_tip, color: context.colors.primary),
                      Expanded(
                        child: Column(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.approvalRequired,
                              style: context.textTheme.bodyMedium!.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                            Text(
                              l10n.submittingApproval,
                              style: context.textTheme.bodyMedium!.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CustomTextFormField(
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  hintTxt: l10n.requestAmount,
                  obscureText: false,
                  label: l10n.requestAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textEditingController: _amount,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.cashAmountRequired;
                    }
                    final amount = parseAmount(value!);
                    return amount == null || amount <= 0
                        ? l10n.cashAmountInvalid
                        : null;
                  },
                ),
                CustomTextFormField(
                  hintTxt: l10n.reasonForRequest,
                  obscureText: false,
                  label: l10n.reasonForRequest,
                  textEditingController: _reason,
                  validator: (value) => requestReasonValidator(value, l10n),
                ),
                CustomContainer(
                  borderWidth: 1,
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.requestSummary,
                        style: context.textTheme.bodyLarge!.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(l10n.employee), Text(employee)],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.amount),
                          Text(_amountText(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state is CashRequestSubmitFailed)
                  Text(
                    state.failure.message(l10n),
                    style: context.textTheme.bodyMedium!.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                AppPrimaryButton(
                  onPressed: sending ? null : _submit,
                  child: sending
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(l10n.sendToAdmin),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _amountText(BuildContext context) {
    final amount = parseAmount(_amount.text);
    return amount == null || amount <= 0
        ? '--'
        : formatMoney(context, amount, ExpenseAdvanceDraft.defaultCurrency);
  }
}
