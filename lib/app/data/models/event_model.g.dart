// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SimpleNotificationConfigAdapter
    extends TypeAdapter<SimpleNotificationConfig> {
  @override
  final int typeId = 1;

  @override
  SimpleNotificationConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SimpleNotificationConfig(
      notifyOnDay: fields[0] as bool,
      notifyDaysBefore: (fields[1] as List).cast<int>(),
      notifyTime: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SimpleNotificationConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.notifyOnDay)
      ..writeByte(1)
      ..write(obj.notifyDaysBefore)
      ..writeByte(2)
      ..write(obj.notifyTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleNotificationConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      subtitle: fields[2] as String?,
      description: fields[3] as String,
      detail: fields[4] as String?,
      eventType: fields[5] as String,
      isNotify: fields[6] as bool,
      eventDate: fields[7] as DateTime,
      eventTime: fields[8] as String,
      repeatType: fields[9] as String,
      iconUrl: fields[10] as String?,
      bannerUrl: fields[11] as String?,
      wishes: fields[12] as String?,
      showOnCalendar: fields[13] as bool,
      showNotificationOnOpen: fields[14] as bool,
      categoryId: fields[15] as String?,
      simpleNotificationConfig: fields[18] as SimpleNotificationConfig?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      originalEventId: fields[19] as String?,
      isOccurrence: fields[20] as bool,
      customReminders: (fields[21] as List?)?.cast<CustomReminderConfig>(),
      isLunar: fields[22] as bool,
      originalLunarDate: fields[23] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.subtitle)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.detail)
      ..writeByte(5)
      ..write(obj.eventType)
      ..writeByte(6)
      ..write(obj.isNotify)
      ..writeByte(7)
      ..write(obj.eventDate)
      ..writeByte(8)
      ..write(obj.eventTime)
      ..writeByte(9)
      ..write(obj.repeatType)
      ..writeByte(10)
      ..write(obj.iconUrl)
      ..writeByte(11)
      ..write(obj.bannerUrl)
      ..writeByte(12)
      ..write(obj.wishes)
      ..writeByte(13)
      ..write(obj.showOnCalendar)
      ..writeByte(14)
      ..write(obj.showNotificationOnOpen)
      ..writeByte(15)
      ..write(obj.categoryId)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.simpleNotificationConfig)
      ..writeByte(19)
      ..write(obj.originalEventId)
      ..writeByte(20)
      ..write(obj.isOccurrence)
      ..writeByte(21)
      ..write(obj.customReminders)
      ..writeByte(22)
      ..write(obj.isLunar)
      ..writeByte(23)
      ..write(obj.originalLunarDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
