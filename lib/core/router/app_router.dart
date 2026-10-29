import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/presentation/views/add_employee_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_requests_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/employee_history_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/correction_form_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/pending_corrections_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_flow_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_success_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/change_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
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
  static GoRouter create(AuthCubit authCubit) => GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _CubitListenable(authCubit),
    redirect: (context, state) => _redirect(authCubit.state, state),
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
      // The fixed path must come before /admin/employees/:id
      GoRoute(
        path: AppRoutes.adminAddEmployee,
        builder: (context, state) => const AddEmployeeView(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployee,
        builder: (context, state) => EmployeeHistoryView(
          id: state.pathParameters['id']!,
          name: state.extra is String ? state.extra as String : null,
        ),
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
  /// left alone so it can finish its animation and then go home. Admin
  /// screens are hidden from employees; the database enforces the role.
  static String? _redirect(AuthSessionState auth, GoRouterState state) {
    final location = state.matchedLocation;
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
                (location.startsWith(AppRoutes.adminPrefix) && !user.isAdmin)
            ? AppRoutes.home
            : null,
    };
  }
}

/// Tells the router to run its redirect again when the cubit changes.
class _CubitListenable extends ChangeNotifier {
  _CubitListenable(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthSessionState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
