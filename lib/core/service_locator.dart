import 'package:get_it/get_it.dart';

import '../features/product/data/repositories/product_repository_impl.dart';
import '../features/product/domain/repositories/product_repository.dart';
import '../features/product/domain/usecases/product_usecases.dart';
import '../features/product/presentation/bloc/product_bloc.dart';

import '../features/shop/data/repositories/shop_repository_impl.dart';
import '../features/shop/domain/repositories/shop_repository.dart';
import '../features/shop/domain/usecases/shop_usecases.dart';
import '../features/shop/presentation/bloc/shop_bloc.dart';

import '../features/settings/data/repositories/printer_repository_impl.dart';
import '../features/settings/domain/repositories/printer_repository.dart';
import '../features/settings/presentation/bloc/printer_bloc.dart';

import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/customers/domain/usecases/customer_usecases.dart';
import '../features/customers/presentation/bloc/customer_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Product
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  // Features - Shop
  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );

  // Features - Settings / Printer
  sl.registerFactory(
    () => PrinterBloc(
      repository: sl(),
    ),
  );

  // Features - Customers
  sl.registerFactory(
    () => CustomerBloc(
      getCustomersUseCase: sl(),
      addCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      deleteCustomerUseCase: sl(),
      getCustomerLedgerUseCase: sl(),
      addCustomerLedgerEntryUseCase: sl(),
      getOpenDebtCycleUseCase: sl(),
      getClosedDebtCyclesUseCase: sl(),
      saveDebtCycleUseCase: sl(),
      getDebtCycleEntriesUseCase: sl(),
    ),
  );

  // Product - Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  // Product - Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );

  // Shop - Use cases
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  // Shop - Repository
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );

  // Printer - Repository
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );

  // Customers - Use cases
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerLedgerUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomerLedgerEntryUseCase(sl()));
  sl.registerLazySingleton(() => GetOpenDebtCycleUseCase(sl()));
  sl.registerLazySingleton(() => GetClosedDebtCyclesUseCase(sl()));
  sl.registerLazySingleton(() => SaveDebtCycleUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtCycleEntriesUseCase(sl()));

  // Customers - Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(),
  );
}