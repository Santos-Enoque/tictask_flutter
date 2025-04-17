// lib/features/auth/di/auth_injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tictask/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tictask/features/auth/domain/repositories/auth_repository.dart';
import 'package:tictask/features/auth/presentation/bloc/auth_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> registerAuthFeature() async {
  // Datasources
  sl..registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabase: Supabase.instance.client),
  )
  
  // Repositories
  ..registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      syncService: sl<SyncService>(),
    ),
  )
  
  // Blocs
  ..registerFactory(
    () => AuthBloc(authRepository: sl()),
  );
}
