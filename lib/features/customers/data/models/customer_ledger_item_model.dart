import 'package:hive/hive.dart';

import '../../domain/entities/customer_ledger_item.dart';

part 'customer_ledger_item_model.g.dart';

@HiveType(typeId: 21)
class CustomerLedgerItemModel extends HiveObject {
  @HiveField(0)
  final String? productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String? internalCode;

  @HiveField(3)
  final String? barcode;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String? localImagePath;

  @HiveField(6)
  final int quantity;

  @HiveField(7)
  final double unitPrice;

  @HiveField(8)
  final double total;

  CustomerLedgerItemModel({
    this.productId,
    required this.productName,
    this.internalCode,
    this.barcode,
    this.imageUrl,
    this.localImagePath,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  CustomerLedgerItem toEntity() {
    return CustomerLedgerItem(
      productId: productId,
      productName: productName,
      internalCode: internalCode,
      barcode: barcode,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
    );
  }

  factory CustomerLedgerItemModel.fromEntity(CustomerLedgerItem item) {
    return CustomerLedgerItemModel(
      productId: item.productId,
      productName: item.productName,
      internalCode: item.internalCode,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      localImagePath: item.localImagePath,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      total: item.total,
    );
  }
}