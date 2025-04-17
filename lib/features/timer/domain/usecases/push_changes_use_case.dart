import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';

class PushChangesUseCase {

  PushChangesUseCase(this._repository);
  final ISyncableTimerRepository _repository;

  Future<int> execute() async {
    return _repository.pushChanges();
  }
}
