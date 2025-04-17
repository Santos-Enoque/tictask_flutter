// lib/features/tasks/di/task_injection.dart
import 'package:get_it/get_it.dart';
import 'package:tictask/features/auth/domain/repositories/auth_repository.dart';
import 'package:tictask/features/tasks/data/repositories/syncable_task_repository_impl.dart';
import 'package:tictask/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_all_tasks_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_task_by_id_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_by_project_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_for_date_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_in_date_range_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/increment_task_pmodoro_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/mark_task_as_completed_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/mark_task_as_in_progress_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/sync_tasks_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:uuid/uuid.dart';

final GetIt sl = GetIt.instance;

Future<void> registerTaskFeature() async {
  // External
  sl.registerLazySingleton<Uuid>(() => const Uuid());
  
  // Repositories
  final taskRepository = TaskRepositoryImpl();
  await taskRepository.init();
  
  final syncableTaskRepository = SyncableTaskRepositoryImpl(sl<AuthRepository>());
  await syncableTaskRepository.init();
  
  sl..registerLazySingleton<ITaskRepository>(
    () => syncableTaskRepository,
  )
  
  // Use cases
  ..registerLazySingleton(() => GetAllTasksUseCase(sl()))
  ..registerLazySingleton(() => GetTaskByIdUseCase(sl()))
  ..registerLazySingleton(() => GetTasksForDateUseCase(sl()))
  ..registerLazySingleton(() => GetTasksInDateRangeUseCase(sl()))
  ..registerLazySingleton(() => GetTasksByProjectUseCase(sl()))
  ..registerLazySingleton(() => CreateTaskUseCase(sl(), sl<Uuid>()))
  ..registerLazySingleton(() => UpdateTaskUseCase(sl()))
  ..registerLazySingleton(() => DeleteTaskUseCase(sl()))
  ..registerLazySingleton(() => MarkTaskAsInProgressUseCase(sl()))
  ..registerLazySingleton(() => MarkTaskAsCompletedUseCase(sl()))
  ..registerLazySingleton(() => IncrementTaskPomodoroUseCase(sl()))
  ..registerLazySingleton(() => SyncTasksUseCase(sl()))
  
  // BLoC
  ..registerFactory(
    () => TaskBloc(
      getAllTasksUseCase: sl(),
      getTasksForDateUseCase: sl(),
      getTasksInDateRangeUseCase: sl(),
      createTaskUseCase: sl(),
      updateTaskUseCase: sl(),
      deleteTaskUseCase: sl(),
      markTaskAsInProgressUseCase: sl(),
      markTaskAsCompletedUseCase: sl(),
      incrementTaskPomodoroUseCase: sl(),
      getTasksByProjectUseCase: sl(),
    ),
  );
}