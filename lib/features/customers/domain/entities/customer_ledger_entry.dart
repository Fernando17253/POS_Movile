import 'package:equatable/equatable.dart';

import 'customer_ledger_item.dart';
import 'payment_split.dart';

class CustomerLedgerEntry extends Equatable {
  final String id;
  final String customerId;
  final String debtCycleId;
  final String type; // product_charge | manual_charge | payment | settlement
  final DateTime createdAt;
  final String description;
  final double amount;
  final double balanceAfter;
  final String? relatedSaleId;
  final List<CustomerLedgerItem> items;
  final List<PaymentSplit> paymentSplits;

  const CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    required this.debtCycleId,
    required this.type,
    required this.createdAt,
    required this.description,
    required this.amount,
    required this.balanceAfter,
    this.relatedSaleId,
    required this.items,
    required this.paymentSplits,
  });

  CustomerLedgerEntry copyWith({
    String? id,
    String? customerId,
    String? debtCycleId,
    String? type,
    DateTime? createdAt,
    String? description,
    double? amount,
    double? balanceAfter,
    String? relatedSaleId,
    List<CustomerLedgerItem>? items,
    List<PaymentSplit>? paymentSplits,
    bool clearRelatedSaleId = false,
  }) {
    return CustomerLedgerEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      debtCycleId: debtCycleId ?? this.debtCycleId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      relatedSaleId: clearRelatedSaleId
          ? null
          : (relatedSaleId ?? this.relatedSaleId),
      items: items ?? this.items,
      paymentSplits: paymentSplits ?? this.paymentSplits,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        debtCycleId,
        type,
        createdAt,
        description,
        amount,
        balanceAfter,
        relatedSaleId,
        items,
        paymentSplits,
      ];
}