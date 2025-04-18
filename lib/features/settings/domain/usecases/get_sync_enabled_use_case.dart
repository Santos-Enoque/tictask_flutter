import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class GetSyncEnabledUseCase {
  final ISettingsRepository _repository;

  GetSyncEnabledUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.getSyncEnabled();
  }
}
