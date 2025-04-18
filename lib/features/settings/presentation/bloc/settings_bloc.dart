import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/usecases/get_notifications_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_sync_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/get_theme_mode_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_notifications_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_sync_enabled_use_case.dart';
import 'package:tictask/features/settings/domain/usecases/save_theme_mode_use_case.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;
  final GetThemeModeUseCase _getThemeModeUseCase;
  final SaveThemeModeUseCase _saveThemeModeUseCase;
  final GetNotificationsEnabledUseCase _getNotificationsEnabledUseCase;
  final SaveNotificationsEnabledUseCase _saveNotificationsEnabledUseCase;
  final GetSyncEnabledUseCase _getSyncEnabledUseCase;
  final SaveSyncEnabledUseCase _saveSyncEnabledUseCase;
  final SyncService?
      _syncService; // Optional service to restart sync when settings change

  SettingsBloc({
    required GetSettingsUseCase getSettingsUseCase,
    required SaveSettingsUseCase saveSettingsUseCase,
    required GetThemeModeUseCase getThemeModeUseCase,
    required SaveThemeModeUseCase saveThemeModeUseCase,
    required GetNotificationsEnabledUseCase getNotificationsEnabledUseCase,
    required SaveNotificationsEnabledUseCase saveNotificationsEnabledUseCase,
    required GetSyncEnabledUseCase getSyncEnabledUseCase,
    required SaveSyncEnabledUseCase saveSyncEnabledUseCase,
    SyncService? syncService,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _saveSettingsUseCase = saveSettingsUseCase,
        _getThemeModeUseCase = getThemeModeUseCase,
        _saveThemeModeUseCase = saveThemeModeUseCase,
        _getNotificationsEnabledUseCase = getNotificationsEnabledUseCase,
        _saveNotificationsEnabledUseCase = saveNotificationsEnabledUseCase,
        _getSyncEnabledUseCase = getSyncEnabledUseCase,
        _saveSyncEnabledUseCase = saveSyncEnabledUseCase,
        _syncService = syncService,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateThemePreference>(_onUpdateThemePreference);
    on<UpdateNotificationsEnabled>(_onUpdateNotificationsEnabled);
    on<UpdateSoundsEnabled>(_onUpdateSoundsEnabled);
    on<UpdateVibrationEnabled>(_onUpdateVibrationEnabled);
    on<UpdateSyncEnabled>(_onUpdateSyncEnabled);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final settings = await _getSettingsUseCase.execute();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      await _saveSettingsUseCase.execute(event.settings);
      emit(SettingsLoaded(event.settings));
    } catch (e) {
      emit(SettingsError('Failed to update settings: $e'));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        await _saveThemeModeUseCase.execute(event.themeMode);

        ThemePreference newPreference;
        switch (event.themeMode) {
          case ThemeMode.light:
            newPreference = ThemePreference.light;
            break;
          case ThemeMode.dark:
            newPreference = ThemePreference.dark;
            break;
          case ThemeMode.system:
          default:
            newPreference = ThemePreference.system;
            break;
        }

        final updatedSettings = currentState.settings.copyWith(
          themePreference: newPreference,
        );

        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update theme mode: $e'));
      }
    }
  }

  Future<void> _onUpdateThemePreference(
    UpdateThemePreference event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        await _saveSettingsUseCase.execute(
          currentState.settings.copyWith(themePreference: event.preference),
        );

        emit(SettingsLoaded(
          currentState.settings.copyWith(themePreference: event.preference),
        ));
      } catch (e) {
        emit(SettingsError('Failed to update theme preference: $e'));
      }
    }
  }

  Future<void> _onUpdateNotificationsEnabled(
    UpdateNotificationsEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        await _saveNotificationsEnabledUseCase.execute(event.enabled);

        emit(SettingsLoaded(
          currentState.settings.copyWith(notificationsEnabled: event.enabled),
        ));
      } catch (e) {
        emit(SettingsError('Failed to update notifications setting: $e'));
      }
    }
  }

  Future<void> _onUpdateSoundsEnabled(
    UpdateSoundsEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        final updatedSettings = currentState.settings.copyWith(
          soundsEnabled: event.enabled,
        );

        await _saveSettingsUseCase.execute(updatedSettings);

        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update sounds setting: $e'));
      }
    }
  }

  Future<void> _onUpdateVibrationEnabled(
    UpdateVibrationEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        final updatedSettings = currentState.settings.copyWith(
          vibrationEnabled: event.enabled,
        );

        await _saveSettingsUseCase.execute(updatedSettings);

        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update vibration setting: $e'));
      }
    }
  }

  Future<void> _onUpdateSyncEnabled(
    UpdateSyncEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      try {
        // Use the SaveSyncEnabledUseCase to save the sync setting
        await _saveSyncEnabledUseCase.execute(event.enabled);

        // Create updated settings for state
        final updatedSettings = currentState.settings.copyWith(
          syncEnabled: event.enabled,
        );

        // Restart sync service if needed
        if (_syncService != null) {
          _syncService!.restartBackgroundSync();
        }

        // Update state
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update sync setting: $e'));
      }
    }
  }
}
