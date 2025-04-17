import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Service to handle all app notifications
/// Currently supports Linux, with plans for mobile and web
class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _vibrationEnabled = true;

  // Notification IDs
  static const int timerCompletedId = 1;
  static const int breakStartId = 2;
  static const int breakEndId = 3;
  static const int taskReminderId = 4;
  static const int dailySummaryId = 5;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      await _loadPreferences();

      if (kIsWeb) {
        // Request permission for web notifications
        // if (html.Notification.supported) {
        //   final permission = await html.Notification.requestPermission();
        //   _initialized = permission == 'granted';
        //   debugPrint('Web notifications permission: $permission');
        // } else {
        //   debugPrint('Web notifications not supported in this browser');
        // }
      } else if (Platform.isLinux) {
        final initializationSettingsLinux = LinuxInitializationSettings(
          defaultActionName: 'Open TicTask',
          defaultIcon: AssetsLinuxIcon('assets/icons/app_icon.png'),
        );

        final initializationSettings = InitializationSettings(
          linux: initializationSettingsLinux,
        );

        await _notificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } else if (Platform.isMacOS) {
        const initializationSettingsMacOS = DarwinInitializationSettings();

        const initializationSettings = InitializationSettings(
          macOS: initializationSettingsMacOS,
        );

        await _notificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      }

      // Request notification permissions if needed
      // This will be needed for mobile platforms in future

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Load user notification preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled =
          prefs.getBool(AppConstants.notificationsEnabledPrefKey) ?? true;
      _soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      // Default to enabled if there's an error
      _notificationsEnabled = true;
      _soundsEnabled = true;
      _vibrationEnabled = true;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Notification tapped with payload: $payload');

      // In the future, you can navigate to specific screens based on payload
      // For example, if payload starts with "task:", open the task screen
    }
  }

  /// Show timer completed notification
  Future<void> showTimerCompletedNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized || !_notificationsEnabled) return;

    try {
      if (kIsWeb) {
        // if (html.Notification.supported) {
        //   html.Notification(
        //     title,
        //     body: body,
        //   );
        // }
      } else if (Platform.isLinux) {
        final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
          category: LinuxNotificationCategory.device,
          sound: _soundsEnabled
              ? AssetsLinuxSound('assets/sounds/bell.wav')
              : null,
        );

        final DarwinNotificationDetails darwinDetails =
            DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _soundsEnabled,
          sound: 'bell.wav',
        );

        final notificationDetails = NotificationDetails(
          linux: linuxDetails,
          macOS: darwinDetails,
        );

        await _notificationsPlugin.show(
          timerCompletedId,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Error showing timer completed notification: $e');
    }
  }

  /// Show break notification
  Future<void> showBreakNotification({
    required String title,
    required String body,
    String? payload,
    bool isBreakStart = true,
  }) async {
    if (!_initialized || !_notificationsEnabled) return;

    try {
      if (kIsWeb) {
        // if (html.Notification.supported) {
        //   html.Notification(
        //     title,
        //     body: body,
        // );
        // }
      } else if (Platform.isLinux) {
        final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
          category: LinuxNotificationCategory.device,
          sound: _soundsEnabled ? ThemeLinuxSound('message') : null,
        );

        final notificationDetails = NotificationDetails(
          linux: linuxDetails,
        );

        await _notificationsPlugin.show(
          isBreakStart ? breakStartId : breakEndId,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Error showing break notification: $e');
    }
  }

  /// Schedule a task reminder notification
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    if (!_initialized || !_notificationsEnabled) return;

    try {
      if (kIsWeb) {
        final now = DateTime.now();
        final delay = reminderTime.difference(now);

        if (delay.isNegative) {
          return;
        }

        Future.delayed(delay, () {
          // if (html.Notification.supported) {
          //   html.Notification(
          //     'Task Reminder',
          //     body: 'Time to work on: $taskTitle',
          //   );
          // }
        });
      } else if (Platform.isLinux) {
        final linuxDetails = LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
          category: LinuxNotificationCategory.device,
          sound: _soundsEnabled ? ThemeLinuxSound('alarm') : null,
        );

        final notificationDetails = NotificationDetails(
          linux: linuxDetails,
        );

        // For Linux, we will just use a delayed show notification
        // since the app needs to be running
        final now = DateTime.now();
        final delay = reminderTime.difference(now);

        if (delay.isNegative) {
          // If the reminder time is in the past, don't schedule
          return;
        }

        // Use a unique ID based on the taskId to allow cancellation
        final notificationId = taskId.hashCode % 10000;

        // Schedule for Linux using a delayed execution
        Future.delayed(delay, () async {
          await _notificationsPlugin.show(
            notificationId,
            'Task Reminder',
            'Time to work on: $taskTitle',
            notificationDetails,
            payload: 'task:$taskId',
          );
        });
      }
    } catch (e) {
      debugPrint('Error scheduling task reminder: $e');
    }
  }

  /// Cancel a specific task reminder
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) return;

    try {
      // Use the same ID calculation as when scheduling
      final notificationId = taskId.hashCode % 10000;
      await _notificationsPlugin.cancel(notificationId);
    } catch (e) {
      debugPrint('Error cancelling task reminder: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Update notification settings
  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? soundsEnabled,
    bool? vibrationEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
        await prefs.setBool(
          AppConstants.notificationsEnabledPrefKey,
          notificationsEnabled,
        );
      }

      if (soundsEnabled != null) {
        _soundsEnabled = soundsEnabled;
        await prefs.setBool('sounds_enabled', soundsEnabled);
      }

      if (vibrationEnabled != null) {
        _vibrationEnabled = vibrationEnabled;
        await prefs.setBool('vibration_enabled', vibrationEnabled);
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }
}
