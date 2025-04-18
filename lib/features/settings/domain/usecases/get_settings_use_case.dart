import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class GetSettingsUseCase {
  final ISettingsRepository _repository;
  
  GetSettingsUseCase(this._repository);
  
  Future<SettingsEntity> execute() async {
    return await _repository.getSettings();
  }
}