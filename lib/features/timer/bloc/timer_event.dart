part of 'timer_bloc.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class TimerInitialized extends TimerEvent {
  const TimerInitialized();
}

class TimerStarted extends TimerEvent {
  final String? taskId;

  const TimerStarted({this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class TimerPaused extends TimerEvent {
  const TimerPaused();
}

class TimerResumed extends TimerEvent {
  const TimerResumed();
}

class TimerReset extends TimerEvent {
  const TimerReset();
}

class TimerTicked extends TimerEvent {
  final int duration;

  const TimerTicked({required this.duration});

  @override
  List<Object> get props => [duration];
}

class TimerConfigChanged extends TimerEvent {
  final TimerConfig config;

  const TimerConfigChanged({required this.config});

  @override
  List<Object> get props => [config];
}

class TimerBreakStarted extends TimerEvent {
  const TimerBreakStarted();
}

class TimerBreakSkipped extends TimerEvent {
  const TimerBreakSkipped();
}

class TimerCompleted extends TimerEvent {
  const TimerCompleted();
}