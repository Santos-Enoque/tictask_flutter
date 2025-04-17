import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/routes/app_router.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/app/theme/app_theme.dart';
import 'package:tictask/app/theme/themes/dark_theme.dart';
import 'package:tictask/app/theme/themes/light_theme.dart';
import 'package:tictask/features/projects/presentation/bloc/project_bloc.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/presentation/bloc/timer_bloc.dart';
import 'package:tictask/injection_container.dart';

/// Main application widget
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthService _authService;
  
  @override
  void initState() {
    super.initState();
    
    // Get auth service
    _authService = sl<AuthService>();
    
    // Setup auth state listener for syncing data
    _authService.setupAuthStateListener();
  }
  
  @override
  Widget build(BuildContext context) {
    final router = getAppRouter();

    return MultiBlocProvider(
      providers: [
        // Global BLoC providers
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc()..add(LoadThemeSettings()),
        ),
        BlocProvider<TimerBloc>(
          create: (_) => sl<TimerBloc>(),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => sl<TaskBloc>(),
        ),
        Provider<TaskRepository>(
          create: (_) => sl<TaskRepository>(),
        ),
        Provider<ProjectRepository>(
          create: (_) => sl<ProjectRepository>(),
        ),
        BlocProvider<ProjectBloc>(
          create: (_) => sl<ProjectBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: getLightTheme(),
            darkTheme: getDarkTheme(),
            themeMode: themeState.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
