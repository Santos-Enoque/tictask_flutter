import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class SaveNotificationsEnabledUseCase {
  final ISettingsRepository _repository;

  SaveNotificationsEnabledUseCase(this._repository);

  Future<void> execute(bool enabled) async {
    await _repository.saveNotificationsEnabled(enabled);
  }
}
