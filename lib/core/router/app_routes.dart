/// Route paths for every screen in the Figma design.
abstract final class AppRoutes {
  static const splash = '/';

  // Auth
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';

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
  static const attendanceCorrection = '/attendance/:id/correction';
  static String attendanceCorrectionOf(String id) =>
      '/attendance/$id/correction';

  // Admin only (see AppRouter's redirect)
  static const adminPrefix = '/admin';
  static const adminDashboard = '/admin';
  static const adminCorrections = '/admin/corrections';
  static const adminRequests = '/admin/requests';
  static const adminAddEmployee = '/admin/employees/new';
  static const adminEmployee = '/admin/employees/:id';
  static String adminEmployeeOf(String id) => '/admin/employees/$id';

  // Cash requests. Overtime has no screens: it is calculated automatically.
  static const cashRequest = '/cash';
  static const newCashRequest = '/new-cash';

  // Settings
  static const settings = '/settings';
  static const language = '/settings/language';
  static const privacy = '/settings/privacy';
}
