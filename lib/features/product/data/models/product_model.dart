import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? barcode;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final double stock;

  @HiveField(5)
  final String? brand;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final String? categoryId;

  @HiveField(8)
  final double cost;

  @HiveField(9)
  final double minStock;

  @HiveField(10)
  final String unitType;

  @HiveField(11)
  final bool isWeighable;

  @HiveField(12)
  final String source;

  @HiveField(13)
  final String internalCode;

  ProductModel({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.stock,
    this.brand,
    this.imageUrl,
    this.categoryId,
    this.cost = 0,
    this.minStock = 0,
    this.unitType = 'piece',
    this.isWeighable = false,
    this.source = 'manual',
    this.internalCode = '',
  });

  Product toEntity() {
    return Product(
      id: id,
      internalCode: internalCode.isNotEmpty ? internalCode : (barcode ?? id),
      name: name,
      barcode: barcode,
      price: price,
      stock: stock,
      brand: brand,
      imageUrl: imageUrl,
      categoryId: categoryId,
      cost: cost,
      minStock: minStock,
      unitType: unitType,
      isWeighable: isWeighable,
      source: source,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      internalCode: product.internalCode,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
      brand: product.brand,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
      cost: product.cost,
      minStock: product.minStock,
      unitType: product.unitType,
      isWeighable: product.isWeighable,
      source: product.source,
    );
  }
}