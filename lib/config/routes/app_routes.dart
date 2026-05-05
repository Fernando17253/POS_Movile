import 'package:go_router/go_router.dart';

import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';

import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_barcode_entry_page.dart';
import '../../features/product/domain/entities/product.dart';

import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

import '../../features/sales/presentation/pages/sales_history_page.dart';

import '../../features/customers/domain/entities/customer.dart';
import '../../features/customers/presentation/pages/customer_list_page.dart';
import '../../features/customers/presentation/pages/upsert_customer_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/add_manual_charge_page.dart';
import '../../features/customers/presentation/pages/register_customer_payment_page.dart';
import '../../features/customers/presentation/pages/select_customer_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'scanner',
          builder: (context, state) => const ScannerPage(),
        ),
        GoRoute(
          path: 'checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    ),

    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesHistoryPage(),
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'barcode-entry',
          builder: (context, state) => const ProductBarcodeEntryPage(),
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            return AddProductPage(
              initialBarcode: extra?['barcode'] as String?,
              initialInternalCode: extra?['internalCode'] as String?,
              initialName: extra?['name'] as String?,
              initialBrand: extra?['brand'] as String?,
              initialImageUrl: extra?['imageUrl'] as String?,
              source: (extra?['source'] as String?) ?? 'manual',
              withoutBarcode: (extra?['withoutBarcode'] as bool?) ?? false,
            );
          },
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product == null) {
              return const ProductListPage();
            }
            return EditProductPage(product: product);
          },
        ),
      ],
    ),

    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerListPage(),
      routes: [
        GoRoute(
          path: 'upsert',
          builder: (context, state) {
            final customer = state.extra as Customer?;
            return UpsertCustomerPage(customer: customer);
          },
        ),
        GoRoute(
          path: 'detail',
          builder: (context, state) {
            final customer = state.extra as Customer?;
            if (customer == null) {
              return const CustomerListPage();
            }
            return CustomerDetailPage(customer: customer);
          },
        ),
        GoRoute(
          path: 'manual-charge',
          builder: (context, state) {
            final customer = state.extra as Customer?;
            if (customer == null) {
              return const CustomerListPage();
            }
            return AddManualChargePage(customer: customer);
          },
        ),
        GoRoute(
          path: 'payment',
          builder: (context, state) {
            final customer = state.extra as Customer?;
            if (customer == null) {
              return const CustomerListPage();
            }
            return RegisterCustomerPaymentPage(customer: customer);
          },
        ),
        GoRoute(
          path: 'select',
          builder: (context, state) => const SelectCustomerPage(),
        ),
      ],
    ),

    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
  ],
);