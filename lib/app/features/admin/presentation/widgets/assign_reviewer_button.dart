import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../permissions/presentation/permissions_context.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/admin_repository.dart';

/// The accounts, loaded once for a review list so every card can name its
/// assigned reviewer and offer the same candidates.
class ReviewerDirectory {
  ReviewerDirectory(this._repository);

  /// The directory for a review list, or `null` where the accounts can't
  /// be read (no [AdminRepository] above).
  static ReviewerDirectory? of(BuildContext context) {
    try {
      return ReviewerDirectory(context.read<AdminRepository>());
    } on ProviderNotFoundException {
      return null;
    }
  }

  final AdminRepository _repository;

  late final Future<List<EmployeeEntity>> employees = _repository
      .getEmployees();
}

/// Admin only: who a pending request is assigned to, and a sheet to choose
/// an employee who holds the matching review permission (or to remove the
/// assignment). The database checks all of it again: an admin caller, an
/// active reviewer with the permission, a pending request, never the
/// requester.
class AssignReviewerButton extends StatelessWidget {
  const AssignReviewerButton({
    super.key,
    required this.requestId,
    required this.requesterId,
    required this.assignedReviewerId,
    required this.holdsPermission,
    required this.onAssign,
  });

  final String requestId;
  final String requesterId;
  final String? assignedReviewerId;

  /// Whether an employee holds this kind of request's review permission.
  final bool Function(EmployeeEntity employee) holdsPermission;

  /// Saves the choice (`null` removes it) and reloads the list. Returns the
  /// error to show, or `null`.
  final Future<String?> Function(String? reviewerId) onAssign;

  @override
  Widget build(BuildContext context) {
    if (!context.permissions.isAdmin) return const SizedBox.shrink();
    final ReviewerDirectory? directory;
    try {
      directory = context.read<ReviewerDirectory?>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    if (directory == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return FutureBuilder<List<EmployeeEntity>>(
      future: directory.employees,
      builder: (context, snapshot) {
        final employees = snapshot.data;
        final assigned = employees
            ?.where((employee) => employee.id == assignedReviewerId)
            .firstOrNull;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: Key('assign-$requestId'),
            onPressed: employees == null
                ? null
                : () => _choose(context, employees),
            icon: const Icon(Icons.person_add_alt_outlined, size: 20),
            label: Text(
              assignedReviewerId == null
                  ? l10n.assignReviewer
                  : l10n.assignedTo(assigned?.fullName ?? '…'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _choose(
    BuildContext context,
    List<EmployeeEntity> employees,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final candidates = [
      for (final employee in employees)
        if (employee.canBeAssigned &&
            holdsPermission(employee) &&
            employee.id != requesterId)
          employee,
    ];
    final choice = await showModalBottomSheet<({String? id})>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                l10n.assignReviewer,
                style: context.textTheme.titleMedium,
              ),
            ),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  l10n.noEligibleReviewers,
                  style: AppTextStyles.meta.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            for (final employee in candidates)
              ListTile(
                key: Key('reviewer-${employee.id}'),
                leading: const Icon(Icons.person_outline),
                title: Text(employee.fullName),
                subtitle: Text(employee.employeeCode),
                selected: employee.id == assignedReviewerId,
                onTap: () => Navigator.pop(context, (id: employee.id)),
              ),
            if (assignedReviewerId != null)
              ListTile(
                key: const Key('unassignReviewer'),
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: context.colors.error,
                ),
                title: Text(l10n.unassignReviewer),
                onTap: () => Navigator.pop(context, (id: null)),
              ),
          ],
        ),
      ),
    );
    if (choice == null || choice.id == assignedReviewerId) return;
    final error = await onAssign(choice.id);
    showAppSnackBar(
      messenger,
      error ??
          (choice.id == null ? l10n.reviewerUnassigned : l10n.reviewerAssigned),
      type: error == null ? AppMessageType.success : AppMessageType.error,
    );
  }
}
