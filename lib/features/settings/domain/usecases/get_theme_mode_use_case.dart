import 'package:flutter/material.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class GetThemeModeUseCase {
  
  GetThemeModeUseCase(this._repository);
  final ISettingsRepository _repository;
  
  ThemeMode execute() {
    return _repository.getThemeMode();
  }
}
