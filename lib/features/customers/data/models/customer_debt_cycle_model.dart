import 'package:hive/hive.dart';

import '../../domain/entities/customer_debt_cycle.dart';

part 'customer_debt_cycle_model.g.dart';

@HiveType(typeId: 24)
class CustomerDebtCycleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String customerNameSnapshot;

  @HiveField(3)
  final DateTime openedAt;

  @HiveField(4)
  final DateTime? closedAt;

  @HiveField(5)
  final bool isClosed;

  @HiveField(6)
  final double totalCharged;

  @HiveField(7)
  final double totalPaid;

  @HiveField(8)
  final double finalBalance;

  @HiveField(9)
  final int totalItems;

  @HiveField(10)
  final int movementCount;

  CustomerDebtCycleModel({
    required this.id,
    required this.customerId,
    required this.customerNameSnapshot,
    required this.openedAt,
    this.closedAt,
    required this.isClosed,
    required this.totalCharged,
    required this.totalPaid,
    required this.finalBalance,
    required this.totalItems,
    required this.movementCount,
  });

  CustomerDebtCycle toEntity() {
    return CustomerDebtCycle(
      id: id,
      customerId: customerId,
      customerNameSnapshot: customerNameSnapshot,
      openedAt: openedAt,
      closedAt: closedAt,
      isClosed: isClosed,
      totalCharged: totalCharged,
      totalPaid: totalPaid,
      finalBalance: finalBalance,
      totalItems: totalItems,
      movementCount: movementCount,
    );
  }

  factory CustomerDebtCycleModel.fromEntity(CustomerDebtCycle cycle) {
    return CustomerDebtCycleModel(
      id: cycle.id,
      customerId: cycle.customerId,
      customerNameSnapshot: cycle.customerNameSnapshot,
      openedAt: cycle.openedAt,
      closedAt: cycle.closedAt,
      isClosed: cycle.isClosed,
      totalCharged: cycle.totalCharged,
      totalPaid: cycle.totalPaid,
      finalBalance: cycle.finalBalance,
      totalItems: cycle.totalItems,
      movementCount: cycle.movementCount,
    );
  }
}