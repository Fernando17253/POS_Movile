// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final int typeId = 3;

  @override
  SaleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      items: (fields[2] as List).cast<SaleItemModel>(),
      subtotal: fields[3] as double,
      discount: fields[4] as double,
      total: fields[5] as double,
      paymentMethod: fields[6] as String,
      amountReceived: fields[7] as double?,
      changeAmount: fields[8] as double?,
      transferReference: fields[9] as String?,
      customerId: fields[10] as String?,
      customerName: fields[11] as String?,
      isCustomerLedger: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SaleModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.subtotal)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.amountReceived)
      ..writeByte(8)
      ..write(obj.changeAmount)
      ..writeByte(9)
      ..write(obj.transferReference)
      ..writeByte(10)
      ..write(obj.customerId)
      ..writeByte(11)
      ..write(obj.customerName)
      ..writeByte(12)
      ..write(obj.isCustomerLedger);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
