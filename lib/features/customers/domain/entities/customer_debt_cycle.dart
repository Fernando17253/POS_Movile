import 'package:equatable/equatable.dart';

class CustomerDebtCycle extends Equatable {
  final String id;
  final String customerId;
  final String customerNameSnapshot;
  final DateTime openedAt;
  final DateTime? closedAt;
  final bool isClosed;
  final double totalCharged;
  final double totalPaid;
  final double finalBalance;
  final int totalItems;
  final int movementCount;

  const CustomerDebtCycle({
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

  CustomerDebtCycle copyWith({
    String? id,
    String? customerId,
    String? customerNameSnapshot,
    DateTime? openedAt,
    DateTime? closedAt,
    bool? isClosed,
    double? totalCharged,
    double? totalPaid,
    double? finalBalance,
    int? totalItems,
    int? movementCount,
    bool clearClosedAt = false,
  }) {
    return CustomerDebtCycle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerNameSnapshot:
          customerNameSnapshot ?? this.customerNameSnapshot,
      openedAt: openedAt ?? this.openedAt,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      isClosed: isClosed ?? this.isClosed,
      totalCharged: totalCharged ?? this.totalCharged,
      totalPaid: totalPaid ?? this.totalPaid,
      finalBalance: finalBalance ?? this.finalBalance,
      totalItems: totalItems ?? this.totalItems,
      movementCount: movementCount ?? this.movementCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerNameSnapshot,
        openedAt,
        closedAt,
        isClosed,
        totalCharged,
        totalPaid,
        finalBalance,
        totalItems,
        movementCount,
      ];
}