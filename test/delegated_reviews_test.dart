import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/admin_request_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_requests_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/edit_employee_view.dart';
import 'package:efs_work_tracker/app/features/assigned_reviews/data/repositories/supabase_assigned_review_repository.dart';
import 'package:efs_work_tracker/app/features/assigned_reviews/domain/repositories/assigned_review_repository.dart';
import 'package:efs_work_tracker/app/features/assigned_reviews/presentation/manager/assigned_reviews_cubit.dart';
import 'package:efs_work_tracker/app/features/assigned_reviews/presentation/views/assigned_reviews_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/data/repositories/supabase_correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/entities/correction_request_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/my_corrections_view.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/cash_request/domain/entities/expense_advance_request_entity.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/home_view.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/entities/permission_set.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/manager/permissions_cubit.dart';
import 'package:efs_work_tracker/app/features/profile/presentation/widgets/pending_email_change.dart';
import 'package:efs_work_tracker/core/enums/request_status.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/errors/correction_errors.dart';
import 'package:efs_work_tracker/core/router/app_router.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_correction_repository.dart';

// The live database's model: an admin gives an employee a reviewer flag,
// assigns them a pending request, and they decide only that request.

const cashReviewer = PermissionSet({Permission.reviewAssignedCash});
const correctionReviewer = PermissionSet({
  Permission.reviewAssignedCorrections,
});
const adminUser = UserEntity(
  uID: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Test Admin',
  username: 'test.admin',
  employeeCode: 'ADM-1',
  role: UserRole.admin,
  isActive: true,
  mustChangePassword: false,
);

ExpenseAdvanceRequestEntity cash(String id) => ExpenseAdvanceRequestEntity(
  id: id,
  amount: 250,
  currency: 'EGP',
  reason: 'Taxi to the client',
  status: RequestStatus.pending,
  createdAt: DateTime.utc(2026, 11, 9, 8),
);

CorrectionRequestEntity correction(
  String id, {
  CorrectionStatus status = CorrectionStatus.pending,
  String? note,
}) => CorrectionRequestEntity(
  id: id,
  employeeId: 'user-1',
  attendanceId: 'day-1',
  proposedCheckIn: DateTime.utc(2026, 11, 8, 6),
  proposedCheckOut: DateTime.utc(2026, 11, 8, 14),
  reason: 'Forgot to check out',
  status: status,
  createdAt: DateTime.utc(2026, 11, 9, 7),
  reviewNote: note,
  workDate: DateTime(2026, 11, 8),
  timezone: 'Africa/Cairo',
);

EmployeeEntity employee(
  String id, {
  bool canReviewCash = false,
  bool isActive = true,
  bool mustChangePassword = false,
  UserRole role = UserRole.employee,
}) => EmployeeEntity(
  id: id,
  fullName: 'Employee $id',
  username: 'employee.$id',
  employeeCode: 'EMP-$id'.toUpperCase(),
  role: role,
  isActive: isActive,
  mustChangePassword: mustChangePassword,
  scheduleId: 'schedule-1',
  canReviewCash: canReviewCash,
);

class FakeAssignedReviewRepository implements AssignedReviewRepository {
  List<ExpenseAdvanceRequestEntity> cashRequests = [];
  List<CorrectionRequestEntity> corrections = [];
  AdminFailure? failure;
  final reads = <String>[];
  final decisions = <(String, String, bool, String?)>[];

  @override
  Future<List<ExpenseAdvanceRequestEntity>> getCash() async {
    reads.add('cash');
    if (failure case final failure?) throw failure;
    return cashRequests;
  }

  @override
  Future<List<CorrectionRequestEntity>> getCorrections() async {
    reads.add('corrections');
    if (failure case final failure?) throw failure;
    return corrections;
  }

  @override
  Future<void> reviewCash(
    String id, {
    required bool approve,
    String? note,
  }) async {
    if (failure case final failure?) throw failure;
    decisions.add(('cash', id, approve, note));
  }

  @override
  Future<void> reviewCorrection(
    String id, {
    required bool approve,
    String? note,
  }) async {
    if (failure case final failure?) throw failure;
    decisions.add(('correction', id, approve, note));
  }
}

/// Records every read and function call; answers reads with [rows].
class RecordingDatabase implements DatabaseServices {
  RecordingDatabase({this.rows = const [], this.error});

  final List<Map<String, dynamic>> rows;
  final Exception? error;
  final reads = <(String, Map<String, dynamic>?)>[];
  final calls = <(String, Map<String, dynamic>?)>[];

  @override
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, Object>? greaterThanOrEqual,
    Map<String, Object>? lessThan,
  }) async {
    reads.add((path, query));
    if (error case final error?) throw error;
    return rows;
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    calls.add((function, params));
    if (error case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('permissions', () {
    test('a reviewer flag opens the assigned screen, not the admin area', () {
      expect(cashReviewer.hasAssignedReviews, isTrue);
      expect(cashReviewer.hasAdminArea, isFalse);
      // The app has no overtime requests: that flag alone opens nothing.
      const overtimeOnly = PermissionSet({Permission.reviewAssignedOvertime});
      expect(overtimeOnly.hasAssignedReviews, isFalse);
      expect(overtimeOnly.hasAdminArea, isFalse);
      // Admins review through their role and hold no flags.
      expect(PermissionSet.fromRole(adminUser).hasAssignedReviews, isFalse);
    });

    test('route guard: reviewers reach only their own screen', () {
      final signedIn = AuthSignedIn(testUser());
      String? at(String route, PermissionSet can) =>
          AppRouter.redirectFor(signedIn, route, permissions: can);

      expect(at(AppRoutes.assignedReviews, cashReviewer), isNull);
      expect(at(AppRoutes.assignedReviews, PermissionSet.none), AppRoutes.home);
      for (final route in [
        AppRoutes.adminDashboard,
        AppRoutes.adminRequests,
        AppRoutes.adminCorrections,
        AppRoutes.adminEmployee,
        AppRoutes.adminEditEmployee,
        AppRoutes.adminEmployeePermissions,
      ]) {
        expect(at(route, cashReviewer), AppRoutes.home, reason: route);
      }
      // Everyone may see their own correction requests.
      expect(at(AppRoutes.myCorrections, PermissionSet.none), isNull);
      // Editing an employee is for the admin role.
      expect(
        at(AppRoutes.adminEditEmployee, PermissionSet.fromRole(adminUser)),
        isNull,
      );
    });

    test('the cubit reads flags for employees only; a removal shows on '
        'refresh', () async {
      final repository = _FlagRepository()
        ..mine = {Permission.reviewAssignedCash};
      final cubit = PermissionsCubit(repository, enabled: true);
      addTearDown(cubit.close);

      await cubit.userChanged(testUser());
      expect(cubit.state.hasAssignedReviews, isTrue);

      repository.mine = {};
      await cubit.refresh();
      expect(cubit.state.hasAssignedReviews, isFalse);

      // An admin's permissions come from the role; nothing is read.
      final readsBefore = repository.reads;
      await cubit.userChanged(adminUser);
      expect(repository.reads, readsBefore);
      expect(cubit.state, PermissionSet.fromRole(adminUser));
    });
  });

  group('SupabaseAssignedReviewRepository', () {
    test(
      'reads only my pending assignments and uses review_assigned_*',
      () async {
        final database = RecordingDatabase();
        final repository = SupabaseAssignedReviewRepository(
          databaseServices: database,
          currentUserId: () => 'emp-1',
        );
        await repository.getCash();
        await repository.getCorrections();
        expect(database.reads.map((r) => r.$1), [
          'expense_advance_requests',
          'attendance_correction_requests',
        ]);
        for (final (_, query) in database.reads) {
          expect(query, {'assigned_reviewer_id': 'emp-1', 'status': 'pending'});
        }

        await repository.reviewCash('c1', approve: true, note: '  ok ');
        // A correction decision needs a reason: without one nothing is sent.
        for (final note in [null, '', '  ']) {
          expect(
            () => repository.reviewCorrection('k1', approve: false, note: note),
            throwsA(AdminFailure.invalidReason),
          );
        }
        await repository.reviewCorrection('k1', approve: false, note: ' no ');
        expect(database.calls[0].$1, 'review_assigned_expense_advance');
        expect(database.calls[0].$2, {
          'p_request_id': 'c1',
          'p_approve': true,
          'p_note': 'ok',
        });
        expect(database.calls[1].$1, 'review_assigned_attendance_correction');
        expect(database.calls, hasLength(2));
        expect(database.calls[1].$2!['p_note'], 'no');
      },
    );

    test('refusals: not assigned, already reviewed, day changed', () async {
      AdminFailure map(String message, String code) =>
          SupabaseAdminRepository.failureFor(code, message);
      expect(
        map('Request is not assigned to you', '42501'),
        AdminFailure.notAllowed,
      );
      expect(
        map('Cash advance review permission required', '42501'),
        AdminFailure.notAllowed,
      );
      expect(
        map('This request has already been reviewed', 'P0001'),
        AdminFailure.alreadyReviewed,
      );
      expect(
        map('Attendance changed; reject this request', 'P0001'),
        AdminFailure.attendanceChanged,
      );
      // Assignment and profile editing.
      expect(
        map('Only pending requests can be assigned', '22023'),
        AdminFailure.alreadyReviewed,
      );
      expect(
        map('Employees cannot be assigned their own requests', '42501'),
        AdminFailure.ownRequest,
      );
      expect(map('Employee not found', '22023'), AdminFailure.notFound);
      expect(
        map('Login email already exists', '23505'),
        AdminFailure.accountConflict,
      );
      // Still a pending correction, not an account conflict.
      expect(
        map('A pending correction already exists', '23505'),
        AdminFailure.pendingCorrection,
      );
    });

    test('signed out: nothing is read', () async {
      final database = RecordingDatabase();
      final repository = SupabaseAssignedReviewRepository(
        databaseServices: database,
        currentUserId: () => null,
      );
      expect(repository.getCash, throwsA(AdminFailure.notAllowed));
      expect(database.reads, isEmpty);
    });
  });

  group('admin functions', () {
    test(
      'assigning a correction reviewer and listing my own requests',
      () async {
        final database = RecordingDatabase();
        final repository = SupabaseCorrectionRepository(
          databaseServices: database,
          currentUserId: () => 'admin-1',
        );
        await repository.assignReviewer('k1', 'emp-2');
        await repository.assignReviewer('k1', null);
        expect(database.calls.map((c) => c.$1).toSet(), {
          'admin_assign_attendance_correction_reviewer',
        });
        expect(database.calls.last.$2, {
          'p_request_id': 'k1',
          'p_reviewer_id': null,
        });

        await repository.getMine();
        // Filtered by employee: an admin's RLS would return everyone's.
        expect(database.reads.single.$2, {'employee_id': 'admin-1'});
        expect(
          SupabaseCorrectionRepository.failureFor(
            '22023',
            'Only pending requests can be assigned',
          ),
          CorrectionFailure.alreadyReviewed,
        );
      },
    );
  });

  group('AssignedReviewsCubit', () {
    test('loads only the kinds the employee may review', () async {
      final repository = FakeAssignedReviewRepository()
        ..cashRequests = [cash('c1')];
      final cubit = AssignedReviewsCubit(
        repository,
        loadCash: true,
        loadCorrections: false,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(repository.reads, ['cash']);
      expect((cubit.state as AssignedReviewsLoaded).cash, hasLength(1));
    });

    test(
      'a decision removes the request; a refusal keeps it and reloads',
      () async {
        final repository = FakeAssignedReviewRepository()
          ..cashRequests = [cash('c1'), cash('c2')];
        final cubit = AssignedReviewsCubit(
          repository,
          loadCash: true,
          loadCorrections: true,
        );
        addTearDown(cubit.close);
        await cubit.load();

        expect(await cubit.reviewCash('c1', approve: true, note: 'ok'), isNull);
        expect(repository.decisions.single, ('cash', 'c1', true, 'ok'));
        expect((cubit.state as AssignedReviewsLoaded).cash.map((r) => r.id), [
          'c2',
        ]);

        // The permission was removed meanwhile: the list is read again.
        repository.failure = AdminFailure.notAllowed;
        final readsBefore = repository.reads.length;
        expect(
          await cubit.reviewCash('c2', approve: false),
          AdminFailure.notAllowed,
        );
        expect(repository.reads.length, greaterThan(readsBefore));
        expect((cubit.state as AssignedReviewsLoaded).reviewing, isEmpty);
      },
    );
  });

  group('screens', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      PermissionSet? permissions,
      UserEntity? user,
      FakeAdminRepository? admin,
      FakeCorrectionRepository? corrections,
      FakeAssignedReviewRepository? assigned,
      Size size = const Size(390, 844),
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        withAppProviders(
          user: user,
          permissions:
              permissions ?? PermissionSet.fromRole(user ?? testUser()),
          admin: admin,
          corrections: corrections,
          RepositoryProvider<AssignedReviewRepository>.value(
            value: assigned ?? FakeAssignedReviewRepository(),
            child: MaterialApp(
              theme: AppTheme.light,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('home: corrections entry for everyone, reviews only for '
        'reviewers', (tester) async {
      await pump(tester, const HomeView());
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('homeCorrections')), findsOneWidget);
      expect(find.byKey(const Key('homeAssignedReviews')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await pump(tester, const HomeView(), permissions: cashReviewer);
      expect(find.byKey(const Key('homeAssignedReviews')), findsOneWidget);
    });

    testWidgets('home in Arabic on a small phone does not overflow', (
      tester,
    ) async {
      await pump(
        tester,
        const HomeView(),
        permissions: cashReviewer,
        size: const Size(320, 640),
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('assigned to me: approve a cash request with a note', (
      tester,
    ) async {
      final assigned = FakeAssignedReviewRepository()
        ..cashRequests = [cash('c1')];
      await pump(
        tester,
        const AssignedReviewsView(),
        permissions: cashReviewer,
        assigned: assigned,
      );
      expect(tester.takeException(), isNull);
      // Only the kind they hold is read.
      expect(assigned.reads, ['cash']);
      expect(find.textContaining('Taxi to the client'), findsOneWidget);

      await tester.tap(find.byKey(const Key('approve-c1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Approved');
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      expect(assigned.decisions.single, ('cash', 'c1', true, 'Approved'));
      expect(find.byKey(const Key('approve-c1')), findsNothing);
      expect(
        find.text('Nothing is assigned to you right now.'),
        findsOneWidget,
      );
    });

    testWidgets('assigned to me: a correction shows its proposed times', (
      tester,
    ) async {
      final assigned = FakeAssignedReviewRepository()
        ..corrections = [correction('k1')];
      await pump(
        tester,
        const AssignedReviewsView(),
        permissions: correctionReviewer,
        assigned: assigned,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      expect(assigned.reads, ['corrections']);
      expect(find.text('Proposed times'), findsOneWidget);
      expect(find.byKey(const Key('reject-k1')), findsOneWidget);
    });

    testWidgets('admin: assign a cash request to an eligible reviewer', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..requests = [
          AdminRequestEntity(
            id: 'c1',
            employeeId: 'requester',
            employeeName: 'Requester',
            employeeCode: 'EMP-9',
            reason: 'Taxi',
            createdAt: DateTime.utc(2026, 11, 9),
            amount: 250,
            currency: 'EGP',
          ),
        ]
        ..employees = [
          employee('ok', canReviewCash: true),
          employee('noflag'),
          employee('inactive', canReviewCash: true, isActive: false),
          employee('firstlogin', canReviewCash: true, mustChangePassword: true),
          // Never the requester, even with the permission.
          employee('requester', canReviewCash: true),
        ];
      await pump(
        tester,
        const AdminRequestsView(),
        user: adminUser,
        admin: admin,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('assign-c1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reviewer-ok')), findsOneWidget);
      for (final id in ['noflag', 'inactive', 'firstlogin', 'requester']) {
        expect(find.byKey(Key('reviewer-$id')), findsNothing, reason: id);
      }

      await tester.tap(find.byKey(const Key('reviewer-ok')));
      await tester.pumpAndSettle();
      expect(admin.cashAssignments.single, ('c1', 'ok'));
      expect(find.text('Reviewer assigned.'), findsOneWidget);
    });

    testWidgets('my corrections: empty, then a reviewed request with its '
        'note', (tester) async {
      final corrections = FakeCorrectionRepository();
      await pump(tester, const MyCorrectionsView(), corrections: corrections);
      expect(find.text('No correction requests'), findsOneWidget);
      expect(find.byKey(const Key('newCorrection')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      corrections.requests = [
        correction(
          'k1',
          status: CorrectionStatus.rejected,
          note: 'Times do not match the gate log',
        ),
      ];
      await pump(
        tester,
        const MyCorrectionsView(),
        corrections: corrections,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Rejected'), findsOneWidget);
      expect(
        find.textContaining('Times do not match the gate log'),
        findsOneWidget,
      );
    });

    testWidgets('edit employee: invalid input is not sent; valid input is '
        'normalized and saved', (tester) async {
      final admin = FakeAdminRepository()..employees = [employee('e1')];
      await pump(
        tester,
        const EditEmployeeView(employeeId: 'e1'),
        user: adminUser,
        admin: admin,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('employee@example.com'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('editUsername')), 'x');
      await tester.tap(find.byKey(const Key('saveEmployee')));
      await tester.pumpAndSettle();
      expect(admin.edits, isEmpty);

      await tester.enterText(
        find.byKey(const Key('editFullName')),
        ' Mona Ali ',
      );
      await tester.enterText(find.byKey(const Key('editUsername')), 'Mona.Ali');
      await tester.enterText(
        find.byKey(const Key('editEmployeeCode')),
        'emp-7',
      );
      await tester.tap(find.byKey(const Key('saveEmployee')));
      await tester.pump();
      expect(admin.edits.single, ('e1', 'Mona Ali', 'mona.ali', 'EMP-7'));
    });

    testWidgets('edit employee: request and cancel a login email change', (
      tester,
    ) async {
      final admin = FakeAdminRepository()..employees = [employee('e1')];
      await pump(
        tester,
        const EditEmployeeView(employeeId: 'e1'),
        user: adminUser,
        admin: admin,
      );

      // The same address, or an invalid one, is never sent.
      await tester.enterText(
        find.byKey(const Key('newLoginEmail')),
        'employee@example.com',
      );
      await tester.ensureVisible(find.byKey(const Key('requestEmailChange')));
      await tester.tap(find.byKey(const Key('requestEmailChange')));
      await tester.pumpAndSettle();
      expect(admin.emailRequests, isEmpty);

      await tester.enterText(
        find.byKey(const Key('newLoginEmail')),
        ' New@Example.com ',
      );
      await tester.tap(find.byKey(const Key('requestEmailChange')));
      await tester.pumpAndSettle();
      expect(admin.emailRequests.single, ('e1', 'new@example.com'));
      expect(find.textContaining('new@example.com'), findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('cancelEmailChange')));
      await tester.tap(find.byKey(const Key('cancelEmailChange')));
      await tester.pumpAndSettle();
      expect(admin.emailRequests.last, ('e1', null));
      expect(find.byKey(const Key('newLoginEmail')), findsOneWidget);
    });

    testWidgets('edit employee: admin accounts can\'t be edited here', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [employee('a1', role: UserRole.admin)];
      await pump(
        tester,
        const EditEmployeeView(employeeId: 'a1'),
        user: adminUser,
        admin: admin,
      );
      expect(find.byKey(const Key('saveEmployee')), findsNothing);
    });

    testWidgets('profile: an employee confirms the email an admin requested', (
      tester,
    ) async {
      final auth = FakeAuthRepository(signedInUser: testUser())
        ..pendingLoginEmail = 'new@example.com';
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: PendingEmailChange()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('new@example.com'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmEmailChange')));
      await tester.pumpAndSettle();
      expect(auth.confirmedEmails, ['new@example.com']);
      expect(find.byKey(const Key('confirmEmailChange')), findsNothing);

      // No request: nothing is shown.
      auth.pendingLoginEmail = null;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: PendingEmailChange()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pendingEmailChange')), findsNothing);
    });
  });

  test('a database refusal is never shown raw', () {
    // Unknown messages fall back to a generic failure with its own text.
    expect(
      SupabaseAdminRepository.failureFor(
        'XX000',
        'relation "x" does not exist',
      ),
      AdminFailure.unknown,
    );
  });
}

class _FlagRepository extends NoPermissionRepository {
  _FlagRepository();

  Set<String> mine = {};
  int reads = 0;

  @override
  Future<Set<String>> getMine() async {
    reads++;
    return mine;
  }
}
