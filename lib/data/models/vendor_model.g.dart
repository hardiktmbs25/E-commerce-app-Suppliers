// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VendorModelAdapter extends TypeAdapter<VendorModel> {
  @override
  final int typeId = 0;

  @override
  VendorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorModel(
      id: fields[0] as String,
      name: fields[1] as String,
      businessName: fields[2] as String,
      email: fields[3] as String,
      phone: fields[4] as String,
      address: fields[5] as String,
      city: fields[6] as String,
      serviceTypeStr: fields[7] as String,
      profileImageUrl: fields[8] as String?,
      fcmToken: fields[9] as String?,
      isActive: fields[10] as bool,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      totalRevenue: fields[13] as double,
      totalCustomers: fields[14] as int,
      settings: (fields[15] as Map).cast<String, dynamic>(),
      areas: fields[16] == null ? [] : (fields[16] as List).cast<String>(),
      timeSlots: fields[17] == null
          ? ['07:00 AM']
          : (fields[17] as List).cast<String>(),
      planName: fields[18] == null ? 'Basic' : fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VendorModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.businessName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.serviceTypeStr)
      ..writeByte(8)
      ..write(obj.profileImageUrl)
      ..writeByte(9)
      ..write(obj.fcmToken)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.totalRevenue)
      ..writeByte(14)
      ..write(obj.totalCustomers)
      ..writeByte(15)
      ..write(obj.settings)
      ..writeByte(16)
      ..write(obj.areas)
      ..writeByte(17)
      ..write(obj.timeSlots)
      ..writeByte(18)
      ..write(obj.planName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
