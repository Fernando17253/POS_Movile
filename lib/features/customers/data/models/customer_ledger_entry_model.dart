import 'package:hive/hive.dart';

import '../../domain/entities/customer_ledger_entry.dart';
import 'customer_ledger_item_model.dart';
import 'payment_split_model.dart';

part 'customer_ledger_entry_model.g.dart';

@HiveType(typeId: 23)
class CustomerLedgerEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final double amount;

  @HiveField(6)
  final double balanceAfter;

  @HiveField(7)
  final String? relatedSaleId;

  @HiveField(8)
  final List<CustomerLedgerItemModel> items;

  @HiveField(9)
  final List<PaymentSplitModel> paymentSplits;

  CustomerLedgerEntryModel({
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

  CustomerLedgerEntry toEntity() {
    return CustomerLedgerEntry(
      id: id,
      customerId: customerId,
      type: type,
      createdAt: createdAt,
      description: description,
      amount: amount,
      balanceAfter: balanceAfter,
      relatedSaleId: relatedSaleId,
      items: items.map((e) => e.toEntity()).toList(),
      paymentSplits: paymentSplits.map((e) => e.toEntity()).toList(),
    );
  }

  factory CustomerLedgerEntryModel.fromEntity(CustomerLedgerEntry entry) {
    return CustomerLedgerEntryModel(
      id: entry.id,
      customerId: entry.customerId,
      type: entry.type,
      createdAt: entry.createdAt,
      description: entry.description,
      amount: entry.amount,
      balanceAfter: entry.balanceAfter,
      relatedSaleId: entry.relatedSaleId,
      items: entry.items.map(CustomerLedgerItemModel.fromEntity).toList(),
      paymentSplits: entry.paymentSplits.map(PaymentSplitModel.fromEntity).toList(),
    );
  }
}