// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 1;

  @override
  CustomerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      alternatePhone: fields[4] as String?,
      address: fields[5] as String,
      landmark: fields[6] as String?,
      routeId: fields[7] as String?,
      routeName: fields[8] as String?,
      serviceTypeStr: fields[9] as String,
      statusStr: fields[10] as String,
      paymentStatusStr: fields[11] as String,
      pendingAmount: fields[12] as double,
      totalPaid: fields[13] as double,
      notes: fields[14] as String?,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      deliveryOrder: fields[17] as int,
      profileImageUrl: fields[18] as String?,
      metadata: (fields[19] as Map).cast<String, dynamic>(),
      activeSubscriptionIds: (fields[20] as List).cast<String>(),
      billingType: fields[21] as String,
      walletBalance: fields[22] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.alternatePhone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.landmark)
      ..writeByte(7)
      ..write(obj.routeId)
      ..writeByte(8)
      ..write(obj.routeName)
      ..writeByte(9)
      ..write(obj.serviceTypeStr)
      ..writeByte(10)
      ..write(obj.statusStr)
      ..writeByte(11)
      ..write(obj.paymentStatusStr)
      ..writeByte(12)
      ..write(obj.pendingAmount)
      ..writeByte(13)
      ..write(obj.totalPaid)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.deliveryOrder)
      ..writeByte(18)
      ..write(obj.profileImageUrl)
      ..writeByte(19)
      ..write(obj.metadata)
      ..writeByte(20)
      ..write(obj.activeSubscriptionIds)
      ..writeByte(21)
      ..write(obj.billingType)
      ..writeByte(22)
      ..write(obj.walletBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
