// lib/features/timer/di/timer_injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/core/services/notification_service.dart';
import 'package:tictask/features/timer/data/datasources/timer_local_data_source.dart';
import 'package:tictask/features/timer/data/datasources/timer_remote_data_source.dart';
import 'package:tictask/features/timer/data/repositories/syncable_timer_repository_impl.dart';
import 'package:tictask/features/timer/data/repositories/timer_repository_impl.dart';
import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';
import 'package:tictask/features/timer/domain/usecases/get_completed_pomodoro_count_today_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_sessions_by_date_range_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_timer_config_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_timer_state_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_total_completed_pomodoros_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/pull_changes_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/push_changes_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/save_session_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/save_timer_config_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/sync_timer_config_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/update_timer_state_use_case.dart';
import 'package:tictask/features/timer/presentation/bloc/timer_bloc.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> registerTimerFeature() async {
  // Data sources
  sl.registerLazySingleton<TimerLocalDataSource>(
    () => TimerLocalDataSourceImpl(),
  );
  
  // Get user ID for remote data source
  final authService = sl<AuthService>();
  final userId = authService.userId ?? '';
  
  sl.registerLazySingleton<TimerRemoteDataSource>(
    () => TimerRemoteDataSourceImpl(
      supabase: Supabase.instance.client,
      userId: userId,
    ),
  );
  
  // Repositories
  final localDataSource = sl<TimerLocalDataSource>();
  await localDataSource.init();
  
  // Base repository (non-syncable)
  final timerRepository = TimerRepositoryImpl(localDataSource);
  sl.registerLazySingleton<ITimerRepository>(
    () => timerRepository,
  );
  
  // Syncable repository
  final syncableTimerRepository = SyncableTimerRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: sl<TimerRemoteDataSource>(),
    authService: sl<AuthService>(),
  );
  await syncableTimerRepository.init();
  
  sl.registerLazySingleton<ISyncableTimerRepository>(
    () => syncableTimerRepository,
  );
  
  // Use cases
  sl.registerLazySingleton(
    () => GetTimerConfigUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveTimerConfigUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetTimerStateUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => UpdateTimerStateUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveSessionUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetCompletedPomodoroCountTodayUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetTotalCompletedPomodorosUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetSessionsByDateRangeUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => PushChangesUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => PullChangesUseCase(sl<ISyncableTimerRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SyncTimerConfigUseCase(sl<ISyncableTimerRepository>()),
  );
  
  // BLoC
  sl.registerFactory(
    () => TimerBloc(
      getTimerConfigUseCase: sl(),
      saveTimerConfigUseCase: sl(),
      getTimerStateUseCase: sl(),
      updateTimerStateUseCase: sl(),
      saveSessionUseCase: sl(),
      getCompletedPomodoroCountTodayUseCase: sl(),
      getTotalCompletedPomodorosUseCase: sl(),
      notificationService: sl<NotificationService>(),
      taskRepository: sl<ITaskRepository>(),
    ),
  );
}