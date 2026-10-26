import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_flow_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_success_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/views/all_cashes_view.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/views/new_cash_request_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/views/add_overtime_request_view.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/views/overtime_view.dart';
import 'package:efs_work_tracker/app/features/splash/presentation/views/splash_view.dart';
import 'package:go_router/go_router.dart';

import '../../app/features/home/presentation/views/home_view.dart';
import '../../app/features/main_layout/presentation/views/main_layout_view.dart';
import '../../core/widgets/placeholder_view.dart';
import 'app_routes.dart';

/// Replace each [PlaceholderView] with the real view as its feature is built.
abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
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
          StatefulShellBranch(routes: [_route(AppRoutes.history, 'History')]),
          StatefulShellBranch(
            routes: [_route(AppRoutes.notifications, 'Notifications')],
          ),
          StatefulShellBranch(routes: [_route(AppRoutes.profile, 'Profile')]),
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
        builder: (context, state) => AttendanceDetailsView(),
      ),
      // Fixed overtime paths must come before /overtime/:id
      GoRoute(
        path: AppRoutes.overtime,
        builder: (context, state) => OvertimeView(),
      ),
      GoRoute(
        path: AppRoutes.createOvertime,
        builder: (context, state) => AddOvertimeRequest(),
      ),
      GoRoute(
        path: AppRoutes.cashRequest,
        builder: (context, state) => AllCashesView(),
      ),
      GoRoute(
        path: AppRoutes.newCashRequest,
        builder: (context, state) => NewCashRequestView(),
      ),
      _route(AppRoutes.createOvertime, 'Request overtime'),
      _route(AppRoutes.overtimeSubmitted, 'Request submitted'),
      _route(AppRoutes.overtimeDetails, 'Request details'),
      _route(AppRoutes.settings, 'Settings'),
      _route(AppRoutes.language, 'Language'),
      _route(AppRoutes.privacy, 'Privacy & permissions'),
    ],
  );

  static GoRoute _route(String path, String title) => GoRoute(
    path: path,
    builder: (context, state) => PlaceholderView(title: title),
  );
}
