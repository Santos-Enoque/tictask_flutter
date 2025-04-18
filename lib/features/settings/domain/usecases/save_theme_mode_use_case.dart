import 'package:flutter/material.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class SaveThemeModeUseCase {
  
  SaveThemeModeUseCase(this._repository);
  final ISettingsRepository _repository;
  
  Future<void> execute(ThemeMode themeMode) async {
    await _repository.saveThemeMode(themeMode);
  }
}
