// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerConfigModelAdapter extends TypeAdapter<TimerConfigModel> {
  @override
  final int typeId = 1;

  @override
  TimerConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerConfigModel(
      id: fields[0] as String,
      pomoDuration: fields[1] as int,
      shortBreakDuration: fields[2] as int,
      longBreakDuration: fields[3] as int,
      longBreakInterval: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TimerConfigModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pomoDuration)
      ..writeByte(2)
      ..write(obj.shortBreakDuration)
      ..writeByte(3)
      ..write(obj.longBreakDuration)
      ..writeByte(4)
      ..write(obj.longBreakInterval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
