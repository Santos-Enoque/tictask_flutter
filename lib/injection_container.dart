import 'package:get_it/get_it.dart';
import 'package:tictask/features/settings/repositories/settings_repository.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Register repositories
  sl.registerLazySingleton<TimerRepository>(TimerRepository.new);
  await sl<TimerRepository>().init(); // Initialize the repository

  sl.registerLazySingleton<TaskRepository>(TaskRepository.new);
  await sl<TaskRepository>().init(); // Initialize the repository

  sl.registerLazySingleton<SettingsRepository>(SettingsRepository.new);
  await sl<SettingsRepository>().init(); // Initialize the repository

  // Register BLoCs
  sl.registerFactory<TimerBloc>(() => TimerBloc(timerRepository: sl()));

  // Register services/utilities
  // ... will be added as needed
}
