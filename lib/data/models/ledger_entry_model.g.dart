// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerEntryModelAdapter extends TypeAdapter<LedgerEntryModel> {
  @override
  final int typeId = 7;

  @override
  LedgerEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntryModel(
      id: fields[0] as String,
      vendorId: fields[1] as String,
      customerId: fields[2] as String,
      typeStr: fields[3] as String,
      amount: fields[4] as double,
      balanceAfter: fields[5] as double,
      description: fields[6] as String,
      referenceId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      isSynced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.typeStr)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.balanceAfter)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.referenceId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
