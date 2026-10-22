import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/check_in_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/forgot_password_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
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
      GoRoute(path: AppRoutes.splash,builder: (context, state) => SplashScreen(),),

      // Auth
      GoRoute(path: AppRoutes.login,builder: (context, state) => LoginView(),),
      GoRoute(path: AppRoutes.forgotPassword,builder: (context, state) => ForgotPasswordView(),),
      // Bottom navigation tabs, each keeps its own navigation stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayoutView(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => HomeView(),)]),
          StatefulShellBranch(routes: [_route(AppRoutes.history, 'History')]),
          StatefulShellBranch(
            routes: [_route(AppRoutes.notifications, 'Notifications')],
          ),
          StatefulShellBranch(routes: [_route(AppRoutes.profile, 'Profile')]),
        ],
      ),

      // Full-screen routes (no bottom navigation bar)
      GoRoute(path: AppRoutes.checkIn,builder: (context, state) => CheckInView(),),
      _route(AppRoutes.checkInSuccess, 'Checked in'),
      _route(AppRoutes.checkOut, 'Check out'),
      _route(AppRoutes.checkOutSuccess, 'Checked out'),
      GoRoute(path: AppRoutes.attendanceDetails,builder: (context, state) => AttendanceDetailsView(),),
      // Fixed overtime paths must come before /overtime/:id
      _route(AppRoutes.overtime, 'Overtime requests'),
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
