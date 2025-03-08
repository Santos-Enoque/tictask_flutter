import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/themes/dark_theme.dart';
import 'package:tictask/app/theme/themes/light_theme.dart';
import 'package:tictask/features/settings/repositories/settings_repository.dart';
import 'package:tictask/injection_container.dart';

// Theme state with equatable for easy comparisons
class ThemeState extends Equatable {
  const ThemeState({this.themeMode = ThemeMode.system});
  final ThemeMode themeMode;

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
  ThemeModeChanged(this.themeMode);
  final ThemeMode themeMode;

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
  final SettingsRepository _settingsRepository = sl<SettingsRepository>();

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    // Save theme mode to repository
    await _settingsRepository.saveThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onLoadThemeSettings(
    LoadThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    // Load theme mode from repository
    final themeMode = _settingsRepository.getThemeMode();
    emit(state.copyWith(themeMode: themeMode));
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
  const AppThemeProvider({
    required this.child,
    super.key,
  });
  final Widget child;

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
