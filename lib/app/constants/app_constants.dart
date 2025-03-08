/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'TicTask';
  static const String appVersion = '1.0.0';
  
  // Hive box names
  static const String timerConfigBox = 'timer_config_box';
  static const String timerStateBox = 'timer_state_box';
  static const String timerSessionBox = 'timer_session_box';
  static const String tasksBox = 'tasks_box';
  static const String settingsBox = 'settings_box';
  
  // Default settings values
  static const int defaultPomoDuration = 25 * 60; // 25 minutes in seconds
  static const int defaultShortBreakDuration = 5 * 60; // 5 minutes in seconds
  static const int defaultLongBreakDuration = 15 * 60; // 15 minutes in seconds
  static const int defaultLongBreakInterval = 4; // After 4 pomodoros
  
  // Notification channels
  static const String timerNotificationChannelId = 'timer_notification';
  static const String timerNotificationChannelName = 'Timer Notifications';
  static const String timerNotificationChannelDescription = 'Notifications for timer events';
  
  // SharedPreferences keys
  static const String themeModePrefKey = 'theme_mode';
  static const String notificationsEnabledPrefKey = 'notifications_enabled';
}