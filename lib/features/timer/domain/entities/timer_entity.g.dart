// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerModeAdapter extends TypeAdapter<TimerMode> {
  @override
  final int typeId = 4;

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

class TimerStatusAdapter extends TypeAdapter<TimerStatus> {
  @override
  final int typeId = 5;

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
