import 'package:hive/hive.dart';
import '../../domain/entities/sale_item.dart';

part 'sale_item_model.g.dart';

@HiveType(typeId: 2)
class SaleItemModel extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String internalCode;

  @HiveField(3)
  final String? barcode;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String unitType;

  @HiveField(6)
  final int quantity;

  @HiveField(7)
  final double unitPrice;

  @HiveField(8)
  final double total;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.internalCode,
    this.barcode,
    this.imageUrl,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  SaleItem toEntity() {
    return SaleItem(
      productId: productId,
      productName: productName,
      internalCode: internalCode,
      barcode: barcode,
      imageUrl: imageUrl,
      unitType: unitType,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
    );
  }

  factory SaleItemModel.fromEntity(SaleItem item) {
    return SaleItemModel(
      productId: item.productId,
      productName: item.productName,
      internalCode: item.internalCode,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      unitType: item.unitType,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      total: item.total,
    );
  }
}