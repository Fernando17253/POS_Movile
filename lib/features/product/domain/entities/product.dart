import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String barcode;

  // Datos de apoyo
  final String? brand;
  final String? imageUrl;
  final String? categoryId;

  // Datos del negocio
  final double price;
  final double cost;
  final double stock;
  final double minStock;

  // Configuración del producto
  final String unitType; // piece, kg, g, lt, ml, pack, box
  final bool isWeighable;
  final String source; // manual | open_food_facts

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.brand,
    this.imageUrl,
    this.categoryId,
    this.cost = 0,
    this.stock = 0,
    this.minStock = 0,
    this.unitType = 'piece',
    this.isWeighable = false,
    this.source = 'manual',
  });

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    String? brand,
    String? imageUrl,
    String? categoryId,
    double? price,
    double? cost,
    double? stock,
    double? minStock,
    String? unitType,
    bool? isWeighable,
    String? source,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unitType: unitType ?? this.unitType,
      isWeighable: isWeighable ?? this.isWeighable,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        brand,
        imageUrl,
        categoryId,
        price,
        cost,
        stock,
        minStock,
        unitType,
        isWeighable,
        source,
      ];
}