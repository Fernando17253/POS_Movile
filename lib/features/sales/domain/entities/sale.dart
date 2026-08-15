import 'package:equatable/equatable.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final String id;
  final DateTime createdAt;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod; // cash | transfer | point | customer_ledger
  final double? amountReceived;
  final double? changeAmount;
  final String? transferReference;

  final String? customerId;
  final String? customerName;
  final bool isCustomerLedger;

  final bool isPartialCustomerLedger;
  final double? paidAmount;
  final double? pendingAmount;

  const Sale({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.amountReceived,
    this.changeAmount,
    this.transferReference,
    this.customerId,
    this.customerName,
    this.isCustomerLedger = false,
    this.isPartialCustomerLedger = false,
    this.paidAmount,
    this.pendingAmount,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        items,
        subtotal,
        discount,
        total,
        paymentMethod,
        amountReceived,
        changeAmount,
        transferReference,
        customerId,
        customerName,
        isCustomerLedger,
        isPartialCustomerLedger,
        paidAmount,
        pendingAmount,
      ];
}