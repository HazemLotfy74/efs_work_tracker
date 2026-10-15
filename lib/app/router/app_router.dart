import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_view.dart';
import '../features/main_layout/presentation/views/main_layout_view.dart';
import 'app_routes.dart';

/// Replace each [PlaceholderView] with the real view as its feature is built.
abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      // Auth
      _route(AppRoutes.login, 'Sign in'),
      _route(AppRoutes.forgotPassword, 'Forgot password'),

      // Bottom navigation tabs, each keeps its own navigation stack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayoutView(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_route(AppRoutes.home, 'Home')]),
          StatefulShellBranch(routes: [_route(AppRoutes.history, 'History')]),
          StatefulShellBranch(
            routes: [_route(AppRoutes.notifications, 'Notifications')],
          ),
          StatefulShellBranch(routes: [_route(AppRoutes.profile, 'Profile')]),
        ],
      ),

      // Full-screen routes (no bottom navigation bar)
      _route(AppRoutes.checkIn, 'Check in'),
      _route(AppRoutes.checkInSuccess, 'Checked in'),
      _route(AppRoutes.checkOut, 'Check out'),
      _route(AppRoutes.checkOutSuccess, 'Checked out'),
      _route(AppRoutes.attendanceDetails, 'Attendance details'),
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
