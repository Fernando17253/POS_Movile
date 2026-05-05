import 'package:hive_flutter/hive_flutter.dart';

import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/sales/data/models/sale_item_model.dart';
import '../../features/sales/data/models/sale_model.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/customers/data/models/customer_ledger_item_model.dart';
import '../../features/customers/data/models/payment_split_model.dart';
import '../../features/customers/data/models/customer_ledger_entry_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String saleBoxName = 'sales';
  static const String customerBoxName = 'customers';
  static const String customerLedgerBoxName = 'customer_ledger_entries';
  
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShopModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SaleItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SaleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(CustomerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(CustomerLedgerItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(PaymentSplitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(CustomerLedgerEntryModelAdapter());
    }

    await Hive.openBox<CustomerLedgerEntryModel>(customerLedgerBoxName);
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox<SaleModel>(saleBoxName);
    await Hive.openBox<CustomerModel>(customerBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<CustomerLedgerEntryModel> get customerLedgerBox =>
      Hive.box<CustomerLedgerEntryModel>(customerLedgerBoxName);
      
  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);

  static Box<ShopModel> get shopBox =>
      Hive.box<ShopModel>(shopBoxName);

  static Box<SaleModel> get saleBox =>
      Hive.box<SaleModel>(saleBoxName);

  static Box<CustomerModel> get customerBox =>
      Hive.box<CustomerModel>(customerBoxName);

  static Box get settingsBox =>
      Hive.box(settingsBoxName);
}