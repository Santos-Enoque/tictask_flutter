import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class UpdateTimerStateUseCase {

  UpdateTimerStateUseCase(this._repository);
  final ITimerRepository _repository;

  Future<TimerEntity> execute(TimerEntity state) async {
    return _repository.updateTimerState(state);
  }
}
