// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_ledger_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerLedgerEntryModelAdapter
    extends TypeAdapter<CustomerLedgerEntryModel> {
  @override
  final int typeId = 23;

  @override
  CustomerLedgerEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerLedgerEntryModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      type: fields[2] as String,
      createdAt: fields[3] as DateTime,
      description: fields[4] as String?,
      amount: fields[5] as double,
      balanceAfter: fields[6] as double,
      relatedSaleId: fields[7] as String?,
      items: (fields[8] as List).cast<CustomerLedgerItemModel>(),
      paymentSplits: (fields[9] as List).cast<PaymentSplitModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, CustomerLedgerEntryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.balanceAfter)
      ..writeByte(7)
      ..write(obj.relatedSaleId)
      ..writeByte(8)
      ..write(obj.items)
      ..writeByte(9)
      ..write(obj.paymentSplits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerLedgerEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
