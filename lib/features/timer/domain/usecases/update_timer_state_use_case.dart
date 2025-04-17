import 'package:tictask/features/timer/domain/entities/timer_state.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class UpdateTimerStateUseCase {
  
  UpdateTimerStateUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<TimerState> execute(TimerState state) async {
    return _repository.updateTimerState(state);
  }
}
