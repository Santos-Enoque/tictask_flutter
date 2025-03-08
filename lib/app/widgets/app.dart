import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/routes/app_router.dart';
import 'package:tictask/app/theme/app_theme.dart';
import 'package:tictask/app/theme/themes/dark_theme.dart';
import 'package:tictask/app/theme/themes/light_theme.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/injection_container.dart';

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

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
