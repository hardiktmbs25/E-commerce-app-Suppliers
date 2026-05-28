// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryModelAdapter extends TypeAdapter<InventoryModel> {
  @override
  final int typeId = 10;

  @override
  InventoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      productName: fields[2] as String,
      currentStock: fields[3] as double,
      unit: fields[4] as String,
      lowStockAlert: fields[5] as double,
      updatedAt: fields[6] as DateTime,
      category: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.currentStock)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.lowStockAlert)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
