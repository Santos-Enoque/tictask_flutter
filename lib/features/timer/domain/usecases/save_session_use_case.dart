import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class SaveSessionUseCase {

  SaveSessionUseCase(this._repository);
  final ITimerRepository _repository;

  Future<void> execute(TimerSessionEntity session) async {
    await _repository.saveSession(session);
  }
}
