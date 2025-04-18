import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class GetNotificationsEnabledUseCase {
  final ISettingsRepository _repository;

  GetNotificationsEnabledUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.getNotificationsEnabled();
  }
}
