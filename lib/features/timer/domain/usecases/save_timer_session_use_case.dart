import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class SaveTimerSessionUseCase {
  
  SaveTimerSessionUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<void> execute(TimerSession session) async {
    await _repository.saveSession(session);
  }
}
