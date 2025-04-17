import 'package:tictask/features/timer/domain/entities/timer_state.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetTimerStateUseCase {
  
  GetTimerStateUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<TimerState> execute() async {
    return _repository.getTimerState();
  }
}
