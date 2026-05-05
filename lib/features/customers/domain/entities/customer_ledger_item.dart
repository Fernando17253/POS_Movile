import 'package:equatable/equatable.dart';

class CustomerLedgerItem extends Equatable {
  final String? productId;
  final String productName;
  final String? internalCode;
  final String? barcode;
  final String? imageUrl;
  final String? localImagePath;
  final int quantity;
  final double unitPrice;
  final double total;

  const CustomerLedgerItem({
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

  CustomerLedgerItem copyWith({
    String? productId,
    String? productName,
    String? internalCode,
    String? barcode,
    String? imageUrl,
    String? localImagePath,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return CustomerLedgerItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      internalCode: internalCode ?? this.internalCode,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        internalCode,
        barcode,
        imageUrl,
        localImagePath,
        quantity,
        unitPrice,
        total,
      ];
}