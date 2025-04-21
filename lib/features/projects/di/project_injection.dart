import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/features/projects/data/datasources/project_local_data_source.dart';
import 'package:tictask/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:tictask/features/projects/data/repositories/project_repository_impl.dart';
import 'package:tictask/features/projects/data/repositories/syncable_project_repository_impl.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';
import 'package:tictask/features/projects/domain/repositories/i_syncable_project_repository.dart';
import 'package:tictask/features/projects/domain/usecases/add_project_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/delete_project_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/get_all_projects_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/get_project_by_id_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/update_project_use_case.dart';
import 'package:tictask/features/projects/presentation/bloc/project_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> registerProjectFeature() async {
  // Data sources
  sl.registerLazySingleton<ProjectLocalDataSource>(
    () => ProjectLocalDataSourceImpl(),
  );

  // Get user ID for remote data source
  final authService = sl<AuthService>();
  final userId = authService.userId ?? '';

  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(
      supabase: Supabase.instance.client,
      userId: userId,
    ),
  );

  // Initialize local data source once
  final localDataSource = sl<ProjectLocalDataSource>();
  await localDataSource.init();

  // Base repository (non-syncable)
  sl.registerLazySingleton<IProjectRepository>(
    () => ProjectRepositoryImpl(localDataSource),
  );

  // Syncable repository
  sl.registerLazySingleton<ISyncableProjectRepository>(
    () => SyncableProjectRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: sl<ProjectRemoteDataSource>(),
      authService: sl<AuthService>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetAllProjectsUseCase(sl<ISyncableProjectRepository>()),
  );

  sl.registerLazySingleton(
    () => GetProjectByIdUseCase(sl<ISyncableProjectRepository>()),
  );

  sl.registerLazySingleton(
    () => AddProjectUseCase(sl<ISyncableProjectRepository>()),
  );

  sl.registerLazySingleton(
    () => UpdateProjectUseCase(sl<ISyncableProjectRepository>()),
  );

  sl.registerLazySingleton(
    () => DeleteProjectUseCase(sl<ISyncableProjectRepository>()),
  );

  // BLoC
  sl.registerFactory(
    () => ProjectBloc(
      getAllProjectsUseCase: sl(),
      getProjectByIdUseCase: sl(),
      addProjectUseCase: sl(),
      updateProjectUseCase: sl(),
      deleteProjectUseCase: sl(),
    ),
  );
}
