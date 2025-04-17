import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetTimerStateUseCase {

  GetTimerStateUseCase(this._repository);
  final ITimerRepository _repository;

  Future<TimerEntity> execute() async {
    return _repository.getTimerState();
  }
}
