import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetSessionsByDateRangeUseCase {
  
  GetSessionsByDateRangeUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<List<TimerSession>> execute(DateTime startDate, DateTime endDate) async {
    return _repository.getSessionsByDateRange(startDate, endDate);
  }
}
