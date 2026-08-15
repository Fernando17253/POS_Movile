import 'package:hive/hive.dart';
import '../../domain/entities/sale.dart';
import 'sale_item_model.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 3)
class SaleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final List<SaleItemModel> items;

  @HiveField(3)
  final double subtotal;

  @HiveField(4)
  final double discount;

  @HiveField(5)
  final double total;

  @HiveField(6)
  final String paymentMethod;

  @HiveField(7)
  final double? amountReceived;

  @HiveField(8)
  final double? changeAmount;

  @HiveField(9)
  final String? transferReference;

  @HiveField(10)
  final String? customerId;

  @HiveField(11)
  final String? customerName;

  @HiveField(12)
  final bool isCustomerLedger;

  @HiveField(13)
  final bool isPartialCustomerLedger;

  @HiveField(14)
  final double? paidAmount;

  @HiveField(15)
  final double? pendingAmount;

  SaleModel({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.discount,
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

  Sale toEntity() {
    return Sale(
      id: id,
      createdAt: createdAt,
      items: items.map((e) => e.toEntity()).toList(),
      subtotal: subtotal,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      amountReceived: amountReceived,
      changeAmount: changeAmount,
      transferReference: transferReference,
      customerId: customerId,
      customerName: customerName,
      isCustomerLedger: isCustomerLedger,
      isPartialCustomerLedger: isPartialCustomerLedger,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
    );
  }

  factory SaleModel.fromEntity(Sale sale) {
    return SaleModel(
      id: sale.id,
      createdAt: sale.createdAt,
      items: sale.items.map(SaleItemModel.fromEntity).toList(),
      subtotal: sale.subtotal,
      discount: sale.discount,
      total: sale.total,
      paymentMethod: sale.paymentMethod,
      amountReceived: sale.amountReceived,
      changeAmount: sale.changeAmount,
      transferReference: sale.transferReference,
      customerId: sale.customerId,
      customerName: sale.customerName,
      isCustomerLedger: sale.isCustomerLedger,
      isPartialCustomerLedger: sale.isPartialCustomerLedger,
      paidAmount: sale.paidAmount,
      pendingAmount: sale.pendingAmount,
    );
  }
}