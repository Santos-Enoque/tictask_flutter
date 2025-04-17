import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class SyncTimerConfigUseCase {
  
  SyncTimerConfigUseCase(this._repository);
  final ITimerRepository _repository;
  
  Future<void> execute() async {
    await _repository.syncTimerConfig();
  }
}
