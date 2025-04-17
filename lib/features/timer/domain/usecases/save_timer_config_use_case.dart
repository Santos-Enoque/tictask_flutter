import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class SaveTimerConfigUseCase {

  SaveTimerConfigUseCase(this._repository);
  final ITimerRepository _repository;

  Future<void> execute(TimerConfigEntity config) async {
    await _repository.saveTimerConfig(config);
  }
}
