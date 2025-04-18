import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class SaveSyncEnabledUseCase {
  final ISettingsRepository _repository;

  SaveSyncEnabledUseCase(this._repository);

  Future<void> execute(bool enabled) async {
    await _repository.saveSyncEnabled(enabled);
  }
}
