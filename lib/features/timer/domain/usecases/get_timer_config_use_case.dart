import 'package:tictask/features/timer/domain/entities/timer_config.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetTimerConfigUseCase {
  
  GetTimerConfigUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<TimerConfig> execute() async {
    return _repository.getTimerConfig();
  }
}
