import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final String productId;
  final String productName;
  final String internalCode;
  final String? barcode;
  final String? imageUrl;
  final String unitType;
  final int quantity;
  final double unitPrice;
  final double total;

  const SaleItem({
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

  @override
  List<Object?> get props => [
        productId,
        productName,
        internalCode,
        barcode,
        imageUrl,
        unitType,
        quantity,
        unitPrice,
        total,
      ];
}