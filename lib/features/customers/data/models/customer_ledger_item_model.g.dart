// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_ledger_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerLedgerItemModelAdapter
    extends TypeAdapter<CustomerLedgerItemModel> {
  @override
  final int typeId = 21;

  @override
  CustomerLedgerItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerLedgerItemModel(
      productId: fields[0] as String?,
      productName: fields[1] as String,
      internalCode: fields[2] as String?,
      barcode: fields[3] as String?,
      imageUrl: fields[4] as String?,
      localImagePath: fields[5] as String?,
      quantity: fields[6] as int,
      unitPrice: fields[7] as double,
      total: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerLedgerItemModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.internalCode)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.localImagePath)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.unitPrice)
      ..writeByte(8)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerLedgerItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
