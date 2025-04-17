// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerSessionModelAdapter extends TypeAdapter<TimerSessionModel> {
  @override
  final int typeId = 2;

  @override
  TimerSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerSessionModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      startTime: fields[2] as int,
      endTime: fields[3] as int,
      duration: fields[4] as int,
      type: fields[5] as SessionType,
      completed: fields[6] as bool,
      taskId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimerSessionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.completed)
      ..writeByte(7)
      ..write(obj.taskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
