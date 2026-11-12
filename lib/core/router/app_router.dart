import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/presentation/views/add_employee_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_requests_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_attendance_day_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/audit_history_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/employee_details_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/edit_attendance_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/edit_employee_view.dart';
import 'package:efs_work_tracker/app/features/assigned_reviews/presentation/views/assigned_reviews_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/correction_form_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/my_corrections_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/pending_corrections_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_flow_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_success_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/change_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/hr_reports/presentation/views/hr_reports_view.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/entities/permission_set.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/manager/permissions_cubit.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/views/manage_permissions_view.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/views/all_cashes_view.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/views/new_cash_request_view.dart';
import 'package:efs_work_tracker/app/features/history/presentation/views/history_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/profile/presentation/views/profile_view.dart';
import 'package:efs_work_tracker/app/features/splash/presentation/views/splash_view.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../app/features/home/presentation/views/home_view.dart';
import '../../app/features/main_layout/presentation/views/main_layout_view.dart';
import '../../core/widgets/placeholder_view.dart';
import 'app_routes.dart';

/// Replace each [PlaceholderView] with the real view as its feature is built.
abstract final class AppRouter {
  /// Create once (in main.dart). Every navigation, and every change of
  /// [authCubit], passes through [_redirect].
  static GoRouter create(
    AuthCubit authCubit,
    PermissionsCubit permissionsCubit,
  ) => GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _CubitListenable([
      authCubit.stream,
      permissionsCubit.stream,
    ]),
    redirect: (context, state) =>
        _redirect(authCubit.state, permissionsCubit.state, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(),
      ),

      // Auth
      GoRoute(path: AppRoutes.login, builder: (context, state) => LoginView()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordView(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => ChangePasswordView(),
      ),
      // Bottom navigation tabs, each keeps its own navigation stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayoutView(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryView(),
              ),
            ],
          ),
          // No notifications exist in the database yet.
          StatefulShellBranch(
            routes: [_route(AppRoutes.notifications, 'Notifications')],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (no bottom navigation bar)
      // Check-in and check-out: same screens, different AttendanceType.
      GoRoute(
        path: AppRoutes.checkIn,
        builder: (context, state) =>
            const AttendanceFlowView(type: AttendanceType.checkIn),
      ),
      GoRoute(
        path: AppRoutes.checkInSuccess,
        builder: (context, state) =>
            const AttendanceSuccessView(type: AttendanceType.checkIn),
      ),
      GoRoute(
        path: AppRoutes.checkOut,
        builder: (context, state) =>
            const AttendanceFlowView(type: AttendanceType.checkOut),
      ),
      GoRoute(
        path: AppRoutes.checkOutSuccess,
        builder: (context, state) =>
            const AttendanceSuccessView(type: AttendanceType.checkOut),
      ),
      GoRoute(
        path: AppRoutes.attendanceDetails,
        builder: (context, state) =>
            AttendanceDetailsView(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.attendanceCorrection,
        builder: (context, state) =>
            CorrectionFormView(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.assignedReviews,
        builder: (context, state) => const AssignedReviewsView(),
      ),
      GoRoute(
        path: AppRoutes.myCorrections,
        builder: (context, state) => const MyCorrectionsView(),
      ),
      GoRoute(
        path: AppRoutes.adminCorrections,
        builder: (context, state) => const PendingCorrectionsView(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.adminRequests,
        builder: (context, state) => const AdminRequestsView(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const HrReportsView(),
      ),
      // The fixed path must come before /admin/employees/:id
      GoRoute(
        path: AppRoutes.adminAddEmployee,
        builder: (context, state) => const AddEmployeeView(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployee,
        builder: (context, state) => EmployeeDetailsView(
          id: state.pathParameters['id']!,
          name: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminEditEmployee,
        builder: (context, state) =>
            EditEmployeeView(employeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeePermissions,
        builder: (context, state) => ManagePermissionsView(
          employeeId: state.pathParameters['id']!,
          name: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeeAudit,
        builder: (context, state) => AuditHistoryView(
          employeeId: state.pathParameters['id']!,
          name: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAttendanceDay,
        builder: (context, state) =>
            AdminAttendanceDayView(attendanceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.adminEditAttendance,
        builder: (context, state) =>
            EditAttendanceView(attendanceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.cashRequest,
        builder: (context, state) => AllCashesView(),
      ),
      GoRoute(
        path: AppRoutes.newCashRequest,
        builder: (context, state) => NewCashRequestView(),
      ),
      _route(AppRoutes.settings, 'Settings'),
      _route(AppRoutes.language, 'Language'),
      _route(AppRoutes.privacy, 'Privacy & permissions'),
    ],
  );

  static GoRoute _route(String path, String title) => GoRoute(
    path: path,
    builder: (context, state) => PlaceholderView(title: title),
  );

  static const _signedOutRoutes = {AppRoutes.login, AppRoutes.forgotPassword};

  /// Keeps each user on the screens their account allows. The splash is
  /// left alone so it can finish its animation and then go home. Each admin
  /// screen needs its permission ([_allowed]); the database checks the same
  /// permission on every request. Admins may send their own cash requests:
  /// someone else must review them (`review_request` refuses self-review).
  static String? _redirect(
    AuthSessionState auth,
    PermissionSet permissions,
    GoRouterState state,
  ) => redirectFor(
    auth,
    // The route pattern (`/admin/employees/:id`) decides the permission.
    state.fullPath ?? state.matchedLocation,
    permissions: permissions,
  );

  /// Where [auth] may not be at [location], the route to go to instead.
  /// [permissions] default to the role's (admin: everything).
  @visibleForTesting
  static String? redirectFor(
    AuthSessionState auth,
    String location, {
    PermissionSet? permissions,
  }) {
    if (location == AppRoutes.splash) return null;
    return switch (auth) {
      AuthChecking() => AppRoutes.splash,
      AuthSignedOut() =>
        _signedOutRoutes.contains(location) ? null : AppRoutes.login,
      AuthPasswordChangeRequired() =>
        location == AppRoutes.changePassword ? null : AppRoutes.changePassword,
      AuthSignedIn(:final user) =>
        _signedOutRoutes.contains(location) ||
                location == AppRoutes.changePassword ||
                !_allowed(location, permissions ?? PermissionSet.fromRole(user))
            ? AppRoutes.home
            : null,
    };
  }

  static bool _allowed(String route, PermissionSet can) {
    if (route == AppRoutes.assignedReviews) return can.hasAssignedReviews;
    if (!route.startsWith(AppRoutes.adminPrefix)) return true;
    return switch (route) {
      AppRoutes.adminDashboard => can.hasAdminArea,
      AppRoutes.adminCorrections => can.can(Permission.correctionsView),
      AppRoutes.adminRequests => can.can(Permission.cashViewAll),
      AppRoutes.adminReports => can.can(Permission.reportsView),
      // Account creation stays role-based (the employee-accounts function).
      AppRoutes.adminAddEmployee => can.isAdmin,
      AppRoutes.adminEmployee => can.can(Permission.employeesView),
      // admin_edit_employee_profile and the email functions need an admin.
      AppRoutes.adminEditEmployee => can.isAdmin,
      AppRoutes.adminEmployeeAudit => can.can(Permission.auditView),
      AppRoutes.adminEmployeePermissions => can.can(
        Permission.managePermissions,
      ),
      AppRoutes.adminAttendanceDay => can.can(Permission.attendanceViewAll),
      AppRoutes.adminEditAttendance => can.can(Permission.attendanceEdit),
      _ => can.isAdmin,
    };
  }
}

/// Tells the router to run its redirect again when a cubit changes.
class _CubitListenable extends ChangeNotifier {
  _CubitListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final stream in streams) stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
