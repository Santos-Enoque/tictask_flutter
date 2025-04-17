import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetTimerConfigUseCase {

  GetTimerConfigUseCase(this._repository);
  final ITimerRepository _repository;

  Future<TimerConfigEntity> execute() async {
    return _repository.getTimerConfig();
  }
}
