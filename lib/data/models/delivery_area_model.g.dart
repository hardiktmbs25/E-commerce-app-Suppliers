// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_area_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryAreaModelAdapter extends TypeAdapter<DeliveryAreaModel> {
  @override
  final int typeId = 13;

  @override
  DeliveryAreaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryAreaModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      name: fields[2] as String,
      pincode: fields[3] as String?,
      city: fields[4] as String?,
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryAreaModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.pincode)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAreaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
