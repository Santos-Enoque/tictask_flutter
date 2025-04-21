import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tictask/features/settings/domain/usecases/get_theme_mode_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_theme_mode_use_case.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemeModeUseCase _getThemeModeUseCase;
  final SaveThemeModeUseCase _saveThemeModeUseCase;

  ThemeBloc({
    required GetThemeModeUseCase getThemeModeUseCase,
    required SaveThemeModeUseCase saveThemeModeUseCase,
  })  : _getThemeModeUseCase = getThemeModeUseCase,
        _saveThemeModeUseCase = saveThemeModeUseCase,
        super(const ThemeState()) {
    on<InitializeTheme>(_onInitializeTheme);
    on<ThemeModeChanged>(_onThemeModeChanged);
  }

  Future<void> _onInitializeTheme(
    InitializeTheme event, 
    Emitter<ThemeState> emit
  ) async {
    final themeMode = _getThemeModeUseCase.execute();
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event, 
    Emitter<ThemeState> emit
  ) async {
    await _saveThemeModeUseCase.execute(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }
}