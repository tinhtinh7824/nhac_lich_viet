// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_reminder_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomReminderConfigAdapter extends TypeAdapter<CustomReminderConfig> {
  @override
  final int typeId = 2;

  @override
  CustomReminderConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomReminderConfig(
      id: fields[0] as String,
      type: fields[1] as CustomReminderType,
      countdownHours: fields[2] as int?,
      countdownMinutes: fields[3] as int?,
      specificDateTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomReminderConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.countdownHours)
      ..writeByte(3)
      ..write(obj.countdownMinutes)
      ..writeByte(4)
      ..write(obj.specificDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomReminderConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
