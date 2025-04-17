// lib/features/tasks/di/task_injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:tictask/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:tictask/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_for_date.dart';
import 'package:tictask/features/tasks/domain/usecases/save_task.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:uuid/uuid.dart';

final GetIt sl = GetIt.instance;

Future<void> registerTaskFeature() async {
  // External
  sl.registerLazySingleton<Uuid>(() => const Uuid());
  
  // Data sources
  final localDataSource = TaskLocalDataSourceImpl();
  await localDataSource.init();
  sl..registerLazySingleton<TaskLocalDataSource>(() => localDataSource)
  
  ..registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(
      supabase: Supabase.instance.client,
      userId: Supabase.instance.client.auth.currentUser!.id,
    ),
  )
  
  // Repositories
  ..registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      uuid: sl(),
    ),
  )
  
  // Use cases
  ..registerLazySingleton(() => GetTasksForDate(sl()))
  ..registerLazySingleton(() => SaveTask(sl()))
  ..registerLazySingleton(() => MarkTaskAsCompleted(sl()))
  
  // BLoC
  ..registerFactory(
    () => TaskBloc(
      taskRepository: sl(),
      uuid: sl(),
    ),
  );
}
