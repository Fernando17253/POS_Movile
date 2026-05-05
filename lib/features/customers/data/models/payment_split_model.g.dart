// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_split_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentSplitModelAdapter extends TypeAdapter<PaymentSplitModel> {
  @override
  final int typeId = 22;

  @override
  PaymentSplitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentSplitModel(
      method: fields[0] as String,
      amount: fields[1] as double,
      reference: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentSplitModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.reference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentSplitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
