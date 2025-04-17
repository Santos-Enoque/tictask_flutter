import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetTodaysSessionsUseCase {
  
  GetTodaysSessionsUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<List<TimerSession>> execute() async {
    return _repository.getTodaysSessions();
  }
}
