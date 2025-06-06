import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class GetCompletedPomodoroCountTodayUseCase {

  GetCompletedPomodoroCountTodayUseCase(this._repository);
  final ITimerRepository _repository;

  Future<int> execute() async {
    return _repository.getCompletedPomodoroCountToday();
  }
}
