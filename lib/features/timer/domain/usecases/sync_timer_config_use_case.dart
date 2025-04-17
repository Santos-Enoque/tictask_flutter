import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';

class SyncTimerConfigUseCase {

  SyncTimerConfigUseCase(this._repository);
  final ISyncableTimerRepository _repository;

  Future<void> execute() async {
    await _repository.syncTimerConfig();
  }
}
