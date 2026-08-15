// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_debt_cycle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerDebtCycleModelAdapter
    extends TypeAdapter<CustomerDebtCycleModel> {
  @override
  final int typeId = 24;

  @override
  CustomerDebtCycleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerDebtCycleModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      customerNameSnapshot: fields[2] as String,
      openedAt: fields[3] as DateTime,
      closedAt: fields[4] as DateTime?,
      isClosed: fields[5] as bool,
      totalCharged: fields[6] as double,
      totalPaid: fields[7] as double,
      finalBalance: fields[8] as double,
      totalItems: fields[9] as int,
      movementCount: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerDebtCycleModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.customerNameSnapshot)
      ..writeByte(3)
      ..write(obj.openedAt)
      ..writeByte(4)
      ..write(obj.closedAt)
      ..writeByte(5)
      ..write(obj.isClosed)
      ..writeByte(6)
      ..write(obj.totalCharged)
      ..writeByte(7)
      ..write(obj.totalPaid)
      ..writeByte(8)
      ..write(obj.finalBalance)
      ..writeByte(9)
      ..write(obj.totalItems)
      ..writeByte(10)
      ..write(obj.movementCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerDebtCycleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
