class Routes {
  static const String home = '/';
  static const String timer = '/timer';
  static const String tasks = '/tasks';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String calendar = '/calendar';
  static const String notFound = '/404';

  // Authentication routes
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  // Settings sub-routes
  static const String windowSettings = '/settings/window';
  static const String timerSettings = '/settings/timer';
    static const String calendarSettings = '/settings/calendar'; // Add this line

  // Task-specific routes
  static const String timerWithTask = '/timer/task/:taskId';
  
  // Helper method to build task timer route
  static String timerWithTaskPath(String taskId) => '/timer/task/$taskId';
}
