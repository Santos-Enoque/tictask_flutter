import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/themes/dark_theme.dart';
import 'package:tictask/app/theme/themes/light_theme.dart';

// Theme state with equatable for easy comparisons
class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [themeMode];
}

// Theme events
abstract class ThemeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ThemeModeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  ThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// Load saved theme event
class LoadThemeSettings extends ThemeEvent {}

// Theme BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<LoadThemeSettings>(_onLoadThemeSettings);
  }

  void _onThemeModeChanged(ThemeModeChanged event, Emitter<ThemeState> emit) async {
    // Save theme mode to local storage would go here
    // Example: await _themeRepository.saveThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onLoadThemeSettings(LoadThemeSettings event, Emitter<ThemeState> emit) async {
    // Load theme mode from local storage would go here
    // Example: final themeMode = await _themeRepository.getThemeMode();
    // For now, use system theme
    emit(state.copyWith(themeMode: ThemeMode.system));
  }
}

// Helper extension methods for theme
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  void setThemeMode(ThemeMode themeMode) {
    BlocProvider.of<ThemeBloc>(this).add(ThemeModeChanged(themeMode));
  }
}

// Theme app provider
class AppThemeProvider extends StatelessWidget {
  final Widget child;

  const AppThemeProvider({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc()..add(LoadThemeSettings()),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            theme: getLightTheme(),
            darkTheme: getDarkTheme(),
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            home: child,
          );
        },
      ),
    );
  }
}