import 'package:equatable/equatable.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final String id;
  final DateTime createdAt;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod; // cash | transfer | point
  final double? amountReceived;
  final double? changeAmount;
  final String? transferReference;

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
      ];
}