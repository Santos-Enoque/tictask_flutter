import 'package:get_it/get_it.dart';
import 'package:tictask/app/theme/bloc/theme_bloc.dart';
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/settings/data/datasource/settings_local_data_source.dart';
import 'package:tictask/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:tictask/features/settings/domain/usecases/get_notifications_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_sync_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_theme_mode_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_notifications_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_sync_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_theme_mode_use_case.dart';
import 'package:tictask/features/settings/presentation/bloc/settings_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> registerSettingsFeature() async {
  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(),
  );
  
  // Repositories
  final settingsLocalDataSource = sl<SettingsLocalDataSource>();
  await settingsLocalDataSource.init();
  
  final settingsRepository = SettingsRepositoryImpl(settingsLocalDataSource);
  await settingsRepository.init();
  
  sl.registerLazySingleton<ISettingsRepository>(
    () => settingsRepository,
  );
  
  // Use cases
  sl.registerLazySingleton(
    () => GetSettingsUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveSettingsUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetThemeModeUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveThemeModeUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetNotificationsEnabledUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveNotificationsEnabledUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => GetSyncEnabledUseCase(sl<ISettingsRepository>()),
  );
  
  sl.registerLazySingleton(
    () => SaveSyncEnabledUseCase(sl<ISettingsRepository>()),
  );
  
  // BLoCs
  sl.registerFactory(
    () => SettingsBloc(
      getSettingsUseCase: sl(),
      saveSettingsUseCase: sl(),
      getThemeModeUseCase: sl(),
      saveThemeModeUseCase: sl(),
      getNotificationsEnabledUseCase: sl(),
      saveNotificationsEnabledUseCase: sl(),
      getSyncEnabledUseCase: sl(),
      saveSyncEnabledUseCase: sl(),
      syncService: sl<SyncService>(),
    ),
  );
  
  // Register ThemeBloc
  sl.registerFactory(
    () => ThemeBloc(
      getThemeModeUseCase: sl(),
      saveThemeModeUseCase: sl(),
    ),
  );
}