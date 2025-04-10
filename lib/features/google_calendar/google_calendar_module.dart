import 'package:flutter/foundation.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/injection_container.dart' as di;

import 'repositories/google_calendar_task_repository.dart';
import 'services/google_auth_service.dart';
import 'services/google_calendar_service.dart';
import 'services/task_sync_service.dart';

/// Register Google Calendar services and repositories
Future<void> registerGoogleCalendarModule() async {
  // Services
  final authService = GoogleAuthService();
  await authService.init();
  di.sl.registerSingleton<GoogleAuthService>(authService);

  final calendarService = GoogleCalendarService(authService);
  await calendarService.init();
  di.sl.registerSingleton<GoogleCalendarService>(calendarService);

  // Get the task repository from the container
  final taskRepository = di.sl<TaskRepository>();

  // Create the task sync service
  final taskSyncService = TaskSyncService(
    authService,
    calendarService,
    taskRepository,
  );
  await taskSyncService.init();
  di.sl.registerSingleton<TaskSyncService>(taskSyncService);

  // Create the Google Calendar task repository
  final googleCalendarTaskRepository = GoogleCalendarTaskRepository(
    taskRepository,
    taskSyncService,
  );

  // Register the Google Calendar task repository
  di.sl.registerSingleton<GoogleCalendarTaskRepository>(
      googleCalendarTaskRepository);

  debugPrint('Google Calendar module registered successfully');
}
