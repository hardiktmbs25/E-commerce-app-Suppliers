// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// Hand-updated to add HiveField(22) deliverySlots.
// Run `flutter pub run build_runner build` to regenerate fully.

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override
  final int typeId = 2;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionModel(
      id:                   fields[0] as String,
      vendorId:             fields[1] as String,
      customerId:           fields[2] as String,
      customerName:         fields[3] as String,
      serviceTypeStr:       fields[4] as String,
      frequencyStr:         fields[5] as String,
      statusStr:            fields[6] as String,
      quantity:             fields[7] as double,
      unit:                 fields[8] as String,
      pricePerUnit:         fields[9] as double,
      pricePerDelivery:     fields[10] as double,
      deliverySlot:         fields[11] as String,
      startDate:            fields[12] as DateTime,
      endDate:              fields[13] as DateTime?,
      pausedUntil:          fields[14] as DateTime?,
      nextDeliveryDate:     fields[15] as DateTime?,
      customDays:           (fields[16] as List).cast<int>(),
      completedDeliveries:  fields[17] as int,
      pendingDeliveries:    fields[18] as int,
      notes:                fields[19] as String?,
      createdAt:            fields[20] as DateTime,
      updatedAt:            fields[21] as DateTime,
      // Field 22 is new – old cached objects won't have it, defaulting to [].
      deliverySlots: fields[22] != null
          ? (fields[22] as List).cast<String>()
          : <String>[],
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer
      ..writeByte(23) // total fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.serviceTypeStr)
      ..writeByte(5)
      ..write(obj.frequencyStr)
      ..writeByte(6)
      ..write(obj.statusStr)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.unit)
      ..writeByte(9)
      ..write(obj.pricePerUnit)
      ..writeByte(10)
      ..write(obj.pricePerDelivery)
      ..writeByte(11)
      ..write(obj.deliverySlot)
      ..writeByte(12)
      ..write(obj.startDate)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.pausedUntil)
      ..writeByte(15)
      ..write(obj.nextDeliveryDate)
      ..writeByte(16)
      ..write(obj.customDays)
      ..writeByte(17)
      ..write(obj.completedDeliveries)
      ..writeByte(18)
      ..write(obj.pendingDeliveries)
      ..writeByte(19)
      ..write(obj.notes)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt)
      ..writeByte(22)
      ..write(obj.deliverySlots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SubscriptionModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}