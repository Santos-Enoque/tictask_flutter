// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerStateModelAdapter extends TypeAdapter<TimerStateModel> {
  @override
  final int typeId = 3;

  @override
  TimerStateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerStateModel(
      id: fields[0] as String,
      timeRemaining: fields[1] as int,
      status: fields[2] as TimerStatus,
      pomodorosCompleted: fields[3] as int,
      currentTaskId: fields[4] as String?,
      lastUpdateTime: fields[5] as int,
      timerMode: fields[6] as TimerMode,
    );
  }

  @override
  void write(BinaryWriter writer, TimerStateModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timeRemaining)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.pomodorosCompleted)
      ..writeByte(4)
      ..write(obj.currentTaskId)
      ..writeByte(5)
      ..write(obj.lastUpdateTime)
      ..writeByte(6)
      ..write(obj.timerMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerStateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimerStatusAdapter extends TypeAdapter<TimerStatus> {
  @override
  final int typeId = 4;

  @override
  TimerStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimerStatus.idle;
      case 1:
        return TimerStatus.running;
      case 2:
        return TimerStatus.paused;
      case 3:
        return TimerStatus.break_;
      default:
        return TimerStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, TimerStatus obj) {
    switch (obj) {
      case TimerStatus.idle:
        writer.writeByte(0);
        break;
      case TimerStatus.running:
        writer.writeByte(1);
        break;
      case TimerStatus.paused:
        writer.writeByte(2);
        break;
      case TimerStatus.break_:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimerModeAdapter extends TypeAdapter<TimerMode> {
  @override
  final int typeId = 5;

  @override
  TimerMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimerMode.focus;
      case 1:
        return TimerMode.break_;
      default:
        return TimerMode.focus;
    }
  }

  @override
  void write(BinaryWriter writer, TimerMode obj) {
    switch (obj) {
      case TimerMode.focus:
        writer.writeByte(0);
        break;
      case TimerMode.break_:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
