// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceModelAdapter extends TypeAdapter<InvoiceModel> {
  @override
  final int typeId = 5;

  @override
  InvoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      customerId: fields[2] as String,
      customerName: fields[3] as String,
      customerPhone: fields[4] == null ? '' : fields[4] as String,
      customerAddress: fields[5] == null ? '' : fields[5] as String,
      month: fields[6] == null ? 1 : fields[6] as int,
      year: fields[7] == null ? 2024 : fields[7] as int,
      statusStr: fields[8] == null ? 'draft' : fields[8] as String,
      rawLineItems: fields[9] == null
          ? []
          : (fields[9] as List?)
              ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
              .toList(),
      subtotal: fields[10] == null ? 0.0 : fields[10] as double,
      totalDiscount: fields[11] == null ? 0.0 : fields[11] as double,
      extraCharges: fields[12] == null ? 0.0 : fields[12] as double,
      totalAmount: fields[13] == null ? 0.0 : fields[13] as double,
      paidAmount: fields[14] == null ? 0.0 : fields[14] as double,
      pendingAmount: fields[15] == null ? 0.0 : fields[15] as double,
      generatedAt: fields[16] as DateTime,
      dueDate: fields[17] as DateTime,
      paidAt: fields[18] as DateTime?,
      paymentMethod: fields[19] as String?,
      notes: fields[20] as String?,
      deliveryIds:
          fields[21] == null ? [] : (fields[21] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.customerPhone)
      ..writeByte(5)
      ..write(obj.customerAddress)
      ..writeByte(6)
      ..write(obj.month)
      ..writeByte(7)
      ..write(obj.year)
      ..writeByte(8)
      ..write(obj.statusStr)
      ..writeByte(9)
      ..write(obj.rawLineItems)
      ..writeByte(10)
      ..write(obj.subtotal)
      ..writeByte(11)
      ..write(obj.totalDiscount)
      ..writeByte(12)
      ..write(obj.extraCharges)
      ..writeByte(13)
      ..write(obj.totalAmount)
      ..writeByte(14)
      ..write(obj.paidAmount)
      ..writeByte(15)
      ..write(obj.pendingAmount)
      ..writeByte(16)
      ..write(obj.generatedAt)
      ..writeByte(17)
      ..write(obj.dueDate)
      ..writeByte(18)
      ..write(obj.paidAt)
      ..writeByte(19)
      ..write(obj.paymentMethod)
      ..writeByte(20)
      ..write(obj.notes)
      ..writeByte(21)
      ..write(obj.deliveryIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
