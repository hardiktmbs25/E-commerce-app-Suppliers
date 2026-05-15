// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_action_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncActionModelAdapter extends TypeAdapter<SyncActionModel> {
  @override
  final int typeId = 4;

  @override
  SyncActionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncActionModel(
      id: fields[0] as String,
      actionTypeStr: fields[1] as String,
      collection: fields[2] as String,
      documentId: fields[3] as String?,
      payload: (fields[4] as Map).cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] as int,
      isFailed: fields[7] as bool,
      localId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncActionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionTypeStr)
      ..writeByte(2)
      ..write(obj.collection)
      ..writeByte(3)
      ..write(obj.documentId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.isFailed)
      ..writeByte(8)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncActionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
