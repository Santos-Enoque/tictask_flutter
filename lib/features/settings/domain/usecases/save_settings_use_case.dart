import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class SaveSettingsUseCase {
  final ISettingsRepository _repository;
  
  SaveSettingsUseCase(this._repository);
  
  Future<void> execute(SettingsEntity settings) async {
    await _repository.saveSettings(settings);
  }
}