import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/bloc/theme_bloc.dart';

/// Extension method for BuildContext to easily access and update ThemeBloc
extension ThemeExtension on BuildContext {
  /// Get the current ThemeMode
  ThemeMode get currentThemeMode => read<ThemeBloc>().state.themeMode;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Set the theme mode
  void setThemeMode(ThemeMode mode) {
    read<ThemeBloc>().add(ThemeModeChanged(mode));
  }

  /// Toggle between light and dark modes
  void toggleThemeMode() {
    final currentMode = read<ThemeBloc>().state.themeMode;
    ThemeMode newMode;

    if (currentMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else if (currentMode == ThemeMode.dark) {
      newMode = ThemeMode.system;
    } else {
      newMode = ThemeMode.light;
    }

    read<ThemeBloc>().add(ThemeModeChanged(newMode));
  }
}