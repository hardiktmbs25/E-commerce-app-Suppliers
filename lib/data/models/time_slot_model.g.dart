// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_slot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeSlotModelAdapter extends TypeAdapter<TimeSlotModel> {
  @override
  final int typeId = 12;

  @override
  TimeSlotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeSlotModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      label: fields[2] as String,
      startTime: fields[3] as String,
      endTime: fields[4] as String,
      isActive: fields[5] as bool,
      sortOrder: fields[6] as int,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimeSlotModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
