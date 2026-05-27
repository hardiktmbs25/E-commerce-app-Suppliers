// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryModelAdapter extends TypeAdapter<DeliveryModel> {
  @override
  final int typeId = 3;

  @override
  DeliveryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      customerId: fields[2] as String,
      customerName: fields[3] as String,
      customerAddress: fields[4] as String,
      subscriptionId: fields[5] as String?,
      serviceTypeStr: fields[6] as String,
      statusStr: fields[7] as String,
      quantity: fields[8] as double,
      unit: fields[9] as String,
      amount: fields[10] as double,
      scheduledDate: fields[11] as DateTime,
      deliveredAt: fields[12] as DateTime?,
      notes: fields[13] as String?,
      isPaid: fields[14] as bool,
      isSynced: fields[15] as bool,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      routeId: fields[18] as String?,
      routeOrder: fields[19] as int,
      deliverySlot: fields[20] as String,
      isExtraOrder: fields[21] as bool,
      billGenerated: fields[22] as bool,
      invoiceId: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.customerAddress)
      ..writeByte(5)
      ..write(obj.subscriptionId)
      ..writeByte(6)
      ..write(obj.serviceTypeStr)
      ..writeByte(7)
      ..write(obj.statusStr)
      ..writeByte(8)
      ..write(obj.quantity)
      ..writeByte(9)
      ..write(obj.unit)
      ..writeByte(10)
      ..write(obj.amount)
      ..writeByte(11)
      ..write(obj.scheduledDate)
      ..writeByte(12)
      ..write(obj.deliveredAt)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.isPaid)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.routeId)
      ..writeByte(19)
      ..write(obj.routeOrder)
      ..writeByte(20)
      ..write(obj.deliverySlot)
      ..writeByte(21)
      ..write(obj.isExtraOrder)
      ..writeByte(22)
      ..write(obj.billGenerated)
      ..writeByte(23)
      ..write(obj.invoiceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
