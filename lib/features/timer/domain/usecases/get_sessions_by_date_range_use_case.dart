import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetSessionsByDateRangeUseCase {

  GetSessionsByDateRangeUseCase(this._repository);
  final ITimerRepository _repository;

  Future<List<TimerSessionEntity>> execute(DateTime startDate, DateTime endDate) async {
    return _repository.getSessionsByDateRange(startDate, endDate);
  }
}
