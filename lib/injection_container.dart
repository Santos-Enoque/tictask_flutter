import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/app/services/sync_service.dart';
import 'package:tictask/features/projects/bloc/project_bloc.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/features/settings/repositories/settings_repository.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/syncable_task_repository.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Ensure Hive adapters are registered
  await _registerHiveAdapters();

  // Register auth and sync services
sl.registerLazySingleton<AuthService>(AuthService.new);
sl.registerLazySingleton<SyncService>(() => SyncService(sl()));

// Replace existing repositories with syncable versions
// sl.registerLazySingleton<TaskRepository>(TaskRepository.new);
sl.registerLazySingleton<TaskRepository>(() => SyncableTaskRepository(sl()));

// sl.registerLazySingleton<ProjectRepository>(ProjectRepository.new);
// sl.registerLazySingleton<ProjectRepository>(() => SyncableProjectRepository(sl()));

// // sl.registerLazySingleton<TimerRepository>(TimerRepository.new);
// sl.registerLazySingleton<TimerRepository>(() => SyncableTimerRepository(sl()));

  // Register repositories
  sl.registerLazySingleton<TimerRepository>(TimerRepository.new);
  await sl<TimerRepository>().init(); // Initialize the repository

  final taskRepository = TaskRepository();
  await taskRepository.init();
  // sl.registerLazySingleton(() => taskRepository);

  final projectRepository = ProjectRepository();
  await projectRepository.init();
  sl.registerLazySingleton(() => projectRepository);

  sl.registerLazySingleton<SettingsRepository>(SettingsRepository.new);
  await sl<SettingsRepository>().init(); // Initialize the repository

  // Register BLoCs
  sl.registerFactory<TimerBloc>(() => TimerBloc(timerRepository: sl()));
  sl.registerFactory(() => TaskBloc(taskRepository: sl()));
  sl.registerFactory(() => ProjectBloc(projectRepository: sl()));

  // Register services/utilities
  // ... will be added as needed
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
      Hive.registerAdapter(TimerStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TimerModeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    // Then register class adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimerConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimerSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimerStateModelAdapter());
    }

    // Register project adapter
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectAdapter());
    }

    // Register task adapter last to avoid conflicts
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TaskAdapter());
    }

    print('Hive adapters registered successfully');
  } catch (e) {
    print('Error registering Hive adapters: $e');
    // Continue anyway, as the repositories will try to register adapters again
  }
}
