import 'package:equatable/equatable.dart';

import 'customer_ledger_item.dart';
import 'payment_split.dart';

class CustomerLedgerEntry extends Equatable {
  final String id;
  final String customerId;
  final String type; // manual_charge | product_charge | payment | settlement
  final DateTime createdAt;
  final String? description;
  final double amount;
  final double balanceAfter;
  final String? relatedSaleId;
  final List<CustomerLedgerItem> items;
  final List<PaymentSplit> paymentSplits;

  const CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.createdAt,
    this.description,
    required this.amount,
    required this.balanceAfter,
    this.relatedSaleId,
    this.items = const [],
    this.paymentSplits = const [],
  });

  CustomerLedgerEntry copyWith({
    String? id,
    String? customerId,
    String? type,
    DateTime? createdAt,
    String? description,
    double? amount,
    double? balanceAfter,
    String? relatedSaleId,
    List<CustomerLedgerItem>? items,
    List<PaymentSplit>? paymentSplits,
  }) {
    return CustomerLedgerEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      relatedSaleId: relatedSaleId ?? this.relatedSaleId,
      items: items ?? this.items,
      paymentSplits: paymentSplits ?? this.paymentSplits,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
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