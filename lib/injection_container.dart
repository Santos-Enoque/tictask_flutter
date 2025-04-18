import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/core/services/notification_service.dart';
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/auth/di/auth_injection.dart';
import 'package:tictask/features/google_calendar/repositories/google_calendar_task_repository.dart';
import 'package:tictask/features/google_calendar/services/google_auth_service.dart';
import 'package:tictask/features/google_calendar/services/google_calendar_service.dart';
import 'package:tictask/features/google_calendar/services/task_sync_service.dart';
import 'package:tictask/features/projects/presentation/bloc/project_bloc.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/features/projects/repositories/syncable_project_repository.dart';
import 'package:tictask/features/settings/repositories/settings_repository.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/syncable_task_repository.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/presentation/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/repositories/syncable_timer_repository.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Ensure Hive adapters are registered
  await _registerHiveAdapters();

  // Register features
  await registerAuthFeature();
  // Register notification service
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Initialize repositories
  // IMPORTANT: We need to await the initialization of repositories before registering them

  // Timer repository
  final timerRepository = TimerRepository();
  await timerRepository.init();
  sl.registerLazySingleton<TimerRepository>(() => timerRepository);

  // Syncable timer repository
  final syncableTimerRepository = SyncableTimerRepository(sl());
  await syncableTimerRepository.init();
  sl.registerLazySingleton<SyncableTimerRepository>(
      () => syncableTimerRepository);

  // Task repository
  final taskRepository = TaskRepository();
  await taskRepository.init();
  sl.registerLazySingleton<TaskRepository>(() => taskRepository);

  // Syncable task repository
  final syncableTaskRepository = SyncableTaskRepository(sl());
  await syncableTaskRepository.init();
  sl.registerLazySingleton<SyncableTaskRepository>(
      () => syncableTaskRepository);

  // Project repository
  final projectRepository = ProjectRepository();
  await projectRepository.init();
  sl.registerLazySingleton<ProjectRepository>(() => projectRepository);

  // Syncable project repository
  final syncableProjectRepository = SyncableProjectRepository(sl());
  await syncableProjectRepository.init();
  sl.registerLazySingleton<SyncableProjectRepository>(
      () => syncableProjectRepository);

  // Settings repository
  final settingsRepository = SettingsRepository();
  await settingsRepository.init();
  sl.registerLazySingleton<SettingsRepository>(() => settingsRepository);

  // Register sync service after repositories
  sl.registerLazySingleton<SyncService>(() => SyncService(sl()));

  // Register BLoCs
  sl.registerFactory<TimerBloc>(() => TimerBloc(
        timerRepository: sl(),
        notificationService: sl(),
        taskRepository: sl(),
      ));
  sl.registerFactory(
      () => TaskBloc(taskRepository: sl<SyncableTaskRepository>()));
  sl.registerFactory(
      () => ProjectBloc(projectRepository: sl<SyncableProjectRepository>()));
      
  // Initialize and register Google Calendar services
  await _registerGoogleCalendarServices();
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

// Register Google Calendar services
Future<void> _registerGoogleCalendarServices() async {
  try {
    // Google auth service (different from app auth service)
    final googleAuthService = GoogleAuthService();
    await googleAuthService.init();
    sl.registerSingleton<GoogleAuthService>(googleAuthService);
    
    // Google Calendar service
    final googleCalendarService = GoogleCalendarService(googleAuthService);
    await googleCalendarService.init();
    sl.registerSingleton<GoogleCalendarService>(googleCalendarService);
    
    // Get the syncable task repository that's already registered
    final taskRepository = sl<SyncableTaskRepository>();
    
    // Create the task sync service
    final taskSyncService = TaskSyncService(
      googleAuthService,
      googleCalendarService,
      taskRepository,
    );
    await taskSyncService.init();
    sl.registerSingleton<TaskSyncService>(taskSyncService);
    
    // Register the decorated task repository for Google Calendar integration
    final googleCalendarTaskRepository = GoogleCalendarTaskRepository(
      taskRepository,
      taskSyncService,
    );
    
    // Re-register TaskBloc to use the Google Calendar task repository
    sl.unregister<TaskBloc>();
    sl.registerFactory(() => TaskBloc(taskRepository: googleCalendarTaskRepository));
    
    print('Google Calendar services registered successfully');
  } catch (e) {
    print('Error registering Google Calendar services: $e');
    // Don't let Google Calendar integration failure crash the app
  }
}