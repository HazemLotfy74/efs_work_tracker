/// Route paths for every screen in the Figma design.
abstract final class AppRoutes {
  static const splash = '/';

  // Auth
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  // Bottom navigation tabs
  static const home = '/home';
  static const history = '/history';
  static const notifications = '/notifications';
  static const profile = '/profile';

  // Attendance session (check-in and check-out share one step flow)
  static const checkIn = '/check-in';
  static const checkInSuccess = '/check-in/success';
  static const checkOut = '/check-out';
  static const checkOutSuccess = '/check-out/success';

  // Attendance history
  static const attendanceDetails = '/attendance/:id';
  static String attendanceDetailsOf(String id) => '/attendance/$id';

  // Overtime
  static const overtime = '/overtime';
  static const createOvertime = '/overtime/create';
  static const overtimeSubmitted = '/overtime/submitted';
  static const overtimeDetails = '/overtime/:id';
  static String overtimeDetailsOf(String id) => '/overtime/$id';

  // Settings
  static const settings = '/settings';
  static const language = '/settings/language';
  static const privacy = '/settings/privacy';
}
