import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/product_image_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductImageService _productImageService = ProductImageService();

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final box = HiveDatabase.productBox;

      final products = box.values
          .map((productModel) => productModel.toEntity())
          .toList();

      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final box = HiveDatabase.productBox;
      final normalizedBarcode = barcode.trim();

      final productModel = box.values.firstWhere(
        (element) => (element.barcode ?? '').trim() == normalizedBarcode,
        orElse: () => throw Exception('Producto no encontrado'),
      );

      return Right(productModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByInternalCode(
    String internalCode,
  ) async {
    try {
      final box = HiveDatabase.productBox;
      final normalizedInternalCode = internalCode.trim().toUpperCase();

      final productModel = box.values.firstWhere(
        (element) =>
            element.internalCode.trim().toUpperCase() == normalizedInternalCode,
        orElse: () => throw Exception('Producto no encontrado'),
      );

      return Right(productModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);

      await box.put(model.id, model);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);

      await box.put(model.id, model);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      final productModel = box.get(id);

      if (productModel != null) {
        await _productImageService.deleteLocalImage(
          productModel.localImagePath,
        );
      }

      await box.delete(id);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}