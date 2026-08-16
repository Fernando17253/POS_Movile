import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  static const String shopKey = 'shop_details';

  @override
  Future<Either<Failure, Shop>> getShop() async {
    try {
      final box = HiveDatabase.shopBox;
      final shop = box.get(shopKey);
      if (shop != null) {
        return Right(shop);
      } else {
        return const Right(Shop(
            name: 'POS',
            addressLine1: 'Lugar de negocio',
            addressLine2: '---',
            phoneNumber: '+9999999999',
            upiId: 'EjemploCorreoElectronico@gmail.com',
            footerText: 'Muchas gracias por su compra, Esperamos su proxima visita!!!'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(Shop shop) async {
    try {
      final box = HiveDatabase.shopBox;
      final model = ShopModel.fromEntity(shop);
      await box.put(shopKey, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
