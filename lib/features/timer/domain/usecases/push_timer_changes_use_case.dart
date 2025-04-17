import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';

class PushTimerChangesUseCase {
  
  PushTimerChangesUseCase(this._repository);
  final ISyncableTimerRepository _repository;
  
  Future<int> execute() async {
    return _repository.pushChanges();
  }
}
