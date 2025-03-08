import 'package:get_it/get_it.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Register repositories
  sl.registerLazySingleton<TimerRepository>(() => TimerRepository());
  await sl<TimerRepository>().init(); // Initialize the repository
  
  sl.registerLazySingleton<TaskRepository>(() => TaskRepository());
  await sl<TaskRepository>().init(); // Initialize the repository

  // Register BLoCs
  sl.registerFactory<TimerBloc>(() => TimerBloc(timerRepository: sl()));

  // Register services/utilities
  // ... will be added as needed
}