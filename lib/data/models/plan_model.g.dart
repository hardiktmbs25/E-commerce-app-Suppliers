// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanModelAdapter extends TypeAdapter<PlanModel> {
  @override
  final int typeId = 14;

  @override
  PlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      name: fields[2] as String,
      serviceType: fields[3] as String,
      frequencyStr: fields[4] as String,
      quantity: fields[5] as double,
      unit: fields[6] as String,
      pricePerUnit: fields[7] as double,
      deliverySlotIds: (fields[8] as List).cast<String>(),
      deliveryAreaIds: (fields[9] as List).cast<String>(),
      description: fields[10] as String,
      isActive: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlanModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.serviceType)
      ..writeByte(4)
      ..write(obj.frequencyStr)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.pricePerUnit)
      ..writeByte(8)
      ..write(obj.deliverySlotIds)
      ..writeByte(9)
      ..write(obj.deliveryAreaIds)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
