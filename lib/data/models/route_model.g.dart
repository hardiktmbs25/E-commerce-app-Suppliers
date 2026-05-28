// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final int typeId = 8;

  @override
  RouteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      name: fields[2] as String,
      deliveryBoyId: fields[3] as String?,
      deliveryBoyName: fields[4] as String?,
      customerIds: fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      isActive: fields[6] == null ? true : fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      totalCustomers: fields[9] == null ? 0 : fields[9] as int,
      areaName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.deliveryBoyId)
      ..writeByte(4)
      ..write(obj.deliveryBoyName)
      ..writeByte(5)
      ..write(obj.customerIds)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.totalCustomers)
      ..writeByte(10)
      ..write(obj.areaName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
