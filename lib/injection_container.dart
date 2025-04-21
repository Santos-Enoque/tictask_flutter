import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/core/services/notification_service.dart';
import 'package:tictask/features/auth/di/auth_injection.dart';
import 'package:tictask/features/projects/di/project_injection.dart';
import 'package:tictask/features/settings/di/settings_injection.dart';
import 'package:tictask/features/tasks/di/task_injection.dart';
import 'package:tictask/features/timer/di/timer_injection.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/data/models/timer_state_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';
import 'package:tictask/core/services/sync_service.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Ensure Hive adapters are registered
  await _registerHiveAdapters();

  // Register notification service
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Register auth service
  sl.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  // Register sync service
  sl.registerLazySingleton<SyncService>(
    () => SyncService(sl<AuthService>()),
  );

  // Register features
  await registerAuthFeature();
  await registerTaskFeature();
  await registerTimerFeature();
  await registerProjectFeature();
  await registerSettingsFeature();
}

// Register all Hive adapters
Future<void> _registerHiveAdapters() async {
  try {
    // First, register all enum adapters
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(DurationUnitAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ThemePreferenceAdapter());
    }

    // Register timer enum adapters
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TimerModeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TimerStatusAdapter());
    }

    // Then register class adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimerConfigModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimerSessionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimerStateModelAdapter());
    }

    // Register project adapter
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectModelAdapter());
    }

    // Register task adapter last to avoid conflicts
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    print('Hive adapters registered successfully');
  } catch (e) {
    print('Error registering Hive adapters: $e');
    // Continue anyway, as the repositories will try to register adapters again
  }
}
