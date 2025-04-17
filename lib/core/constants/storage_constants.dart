// lib/core/constants/storage_constants.dart
class StorageConstants {
  // Hive box names
  static const String timerConfigBox = 'timer_config_box';
  static const String timerStateBox = 'timer_state_box';
  static const String timerSessionBox = 'timer_session_box';
  static const String tasksBox = 'tasks_box';
  static const String projectsBox = 'projects_box';
  static const String settingsBox = 'settings_box';
  
  // Shared Preferences keys
  static const String themeModePrefKey = 'theme_mode';
  static const String notificationsEnabledPrefKey = 'notifications_enabled';
  static const String syncEnabledPrefKey = 'sync_enabled';
  
  // Sync metadata keys
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String pendingTaskSyncIdsKey = 'pending_task_sync_ids';
  static const String deletedTaskIdsKey = 'deleted_task_ids';
  static const String pendingProjectSyncIdsKey = 'pending_project_sync_ids';
  static const String deletedProjectIdsKey = 'deleted_project_ids';
  static const String pendingTimerSessionSyncIdsKey = 'pending_timer_session_sync_ids';
  static const String deletedTimerSessionIdsKey = 'deleted_timer_session_ids';
}
