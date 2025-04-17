import 'package:tictask/features/timer/domain/entities/timer_config.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class SaveTimerConfigUseCase {
  
  SaveTimerConfigUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<void> execute(TimerConfig config) async {
    await _repository.saveTimerConfig(config);
  }
}
