// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 7;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.todo;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.completed;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.todo:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DurationUnitAdapter extends TypeAdapter<DurationUnit> {
  @override
  final int typeId = 8;

  @override
  DurationUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DurationUnit.minutes;
      case 1:
        return DurationUnit.seconds;
      default:
        return DurationUnit.minutes;
    }
  }

  @override
  void write(BinaryWriter writer, DurationUnit obj) {
    switch (obj) {
      case DurationUnit.minutes:
        writer.writeByte(0);
        break;
      case DurationUnit.seconds:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DurationUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemePreferenceAdapter extends TypeAdapter<ThemePreference> {
  @override
  final int typeId = 9;

  @override
  ThemePreference read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ThemePreference.system;
      case 1:
        return ThemePreference.light;
      case 2:
        return ThemePreference.dark;
      default:
        return ThemePreference.system;
    }
  }

  @override
  void write(BinaryWriter writer, ThemePreference obj) {
    switch (obj) {
      case ThemePreference.system:
        writer.writeByte(0);
        break;
      case ThemePreference.light:
        writer.writeByte(1);
        break;
      case ThemePreference.dark:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
