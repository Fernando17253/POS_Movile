import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:billing_app/features/sales/domain/entities/sale.dart';
import 'package:billing_app/features/sales/domain/entities/sale_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import '../../../customers/domain/entities/customer.dart';
import 'dart:io';

import '../../../../core/data/hive_database.dart';

import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer_ledger_entry.dart';
import '../../../customers/domain/entities/customer_ledger_item.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/domain/entities/customer_debt_cycle.dart';

import '../../../product/data/repositories/product_repository_impl.dart';
import '../../../product/domain/entities/product.dart';

import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _amountReceivedController =
      TextEditingController();
  final TextEditingController _transferReferenceController =
      TextEditingController();

  final TextEditingController _partialPaidController = TextEditingController();

  final _customerRepository = CustomerRepositoryImpl();
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.10);
  final _salesRepository = SalesRepositoryImpl();
  final _productRepository = ProductRepositoryImpl();

  bool _isPartialCustomerLedger = false;
  String _paymentMethod = 'cash'; // cash | transfer | point
  bool _isSavingSale = false;

  Customer? _selectedCustomer;
  bool _sendToCustomerLedger = false;

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  double _calculatePartialPending(double total) {
    final paidNow = _parseDouble(_partialPaidController.text);
    final pending = total - paidNow;
    return pending < 0 ? 0 : pending;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _calculateChange(double total) {
    if (_paymentMethod != 'cash') return 0;
    final received = _parseDouble(_amountReceivedController.text);
    return received - total;
  }

  String _formatStockValue(double value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

String? _validateStockBeforeSale(BillingState billingState) {
  for (final item in billingState.cartItems) {
    final currentStock = item.product.stock;
    final requested = item.quantity.toDouble();

    if (currentStock <= 0) {
      return 'El producto "${item.product.name}" no tiene stock disponible.';
    }

    if (requested > currentStock) {
      return 'Stock insuficiente para "${item.product.name}". '
          'Disponible: ${_formatStockValue(currentStock)} | '
          'Intentas vender: ${item.quantity}.';
    }
  }

  return null;
}

Future<String?> _discountStock(BillingState billingState) async {
  final updatedOriginalProducts = <Product>[];

  for (final item in billingState.cartItems) {
    final originalProduct = item.product;
    final updatedProduct = originalProduct.copyWith(
      stock: originalProduct.stock - item.quantity,
    );

    final result = await _productRepository.updateProduct(updatedProduct);

    bool failed = false;
    String failureMessage = '';

    result.fold(
      (failure) {
        failed = true;
        failureMessage = failure.message;
      },
      (_) {},
    );

    if (failed) {
      for (final original in updatedOriginalProducts) {
        await _productRepository.updateProduct(original);
      }
      return failureMessage;
    }

    updatedOriginalProducts.add(originalProduct);
  }

  return null;
}

Future<void> _restoreStock(List<Product> originalProducts) async {
  for (final product in originalProducts) {
    await _productRepository.updateProduct(product);
  }
}

Future<CustomerDebtCycle?> _getOrCreateOpenDebtCycle(Customer customer) async {
  final openCycleResult = await _customerRepository.getOpenDebtCycle(customer.id);

  return await openCycleResult.fold(
    (_) async => null,
    (existingCycle) async {
      if (existingCycle != null) {
        return existingCycle;
      }

      final newCycle = CustomerDebtCycle(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        customerId: customer.id,
        customerNameSnapshot: customer.name,
        openedAt: DateTime.now(),
        closedAt: null,
        isClosed: false,
        totalCharged: 0,
        totalPaid: 0,
        finalBalance: customer.currentBalance,
        totalItems: 0,
        movementCount: 0,
      );

      final saveResult = await _customerRepository.saveDebtCycle(newCycle);

      return saveResult.fold(
        (_) => null,
        (_) => newCycle,
      );
    },
  );
}

Future<void> _saveSaleToCustomerLedger(BillingState billingState) async {
  if (_selectedCustomer == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un cliente para mandar la venta a libreta.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final total = billingState.totalAmount;
  final currentCustomer = _selectedCustomer!;
  final saleId = DateTime.now().millisecondsSinceEpoch.toString();
  final createdAt = DateTime.now();

  final openCycle = await _getOrCreateOpenDebtCycle(currentCustomer);

if (!mounted) return;

if (openCycle == null) {
  final originalProducts =
      billingState.cartItems.map((item) => item.product).toList();

  await _restoreStock(originalProducts);

  if (!mounted) return;

  setState(() {
    _isSavingSale = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No se pudo crear o recuperar el ciclo de adeudo.'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

final sale = Sale(
  id: saleId,
  createdAt: createdAt,
  items: billingState.cartItems.map((item) {
    return SaleItem(
      productId: item.product.id,
      productName: item.product.name,
      internalCode: item.product.internalCode,
      barcode: item.product.barcode,
      imageUrl: item.product.imageUrl,
      localImagePath: item.product.localImagePath,
      unitType: item.product.unitType,
      quantity: item.quantity,
      unitPrice: item.product.price,
      total: item.total,
    );
  }).toList(),
  subtotal: total,
  discount: 0,
  total: total,
  paymentMethod: 'customer_ledger',
  amountReceived: null,
  changeAmount: null,
  transferReference: null,
  customerId: currentCustomer.id,
  customerName: currentCustomer.name,
  isCustomerLedger: true,
  isPartialCustomerLedger: false,
  paidAmount: 0,
  pendingAmount: total,
);

  final saleResult = await _salesRepository.saveSale(sale);

  if (!mounted) return;

  await saleResult.fold(
    (failure) async {
      final originalProducts =
          billingState.cartItems.map((item) => item.product).toList();

      await _restoreStock(originalProducts);

      if (!mounted) return;

      setState(() {
        _isSavingSale = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la venta en historial: ${failure.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    },
    (_) async {
      final balanceAfter = currentCustomer.currentBalance + total;

      final entry = CustomerLedgerEntry(
  id: '$saleId-ledger',
  customerId: currentCustomer.id,
  debtCycleId: openCycle.id,
  type: 'product_charge',
  createdAt: createdAt,
  description: 'Venta enviada a libreta',
  amount: total,
  balanceAfter: balanceAfter,
  relatedSaleId: saleId,
  items: billingState.cartItems.map((item) {
    return CustomerLedgerItem(
      productId: item.product.id,
      productName: item.product.name,
      internalCode: item.product.internalCode,
      barcode: item.product.barcode,
      imageUrl: item.product.imageUrl,
      localImagePath: item.product.localImagePath,
      quantity: item.quantity,
      unitPrice: item.product.price,
      total: item.total,
    );
  }).toList(),
  paymentSplits: const [],
);

      final ledgerResult = await _customerRepository.addCustomerLedgerEntry(
        entry,
      );

      if (!mounted) return;

      ledgerResult.fold(
        (failure) async {
          await HiveDatabase.saleBox.delete(saleId);

          final originalProducts =
              billingState.cartItems.map((item) => item.product).toList();
          await _restoreStock(originalProducts);

          if (!mounted) return;

          setState(() {
            _isSavingSale = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo guardar la venta en la libreta: ${failure.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          setState(() {
            _isSavingSale = false;
          });

          context.read<ProductBloc>().add(LoadProducts());
          context.read<CustomerBloc>().add(const LoadCustomers());
          context.read<BillingBloc>().add(ClearCartEvent());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Venta enviada a la libreta de ${currentCustomer.name} y guardada en historial.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          context.go('/');
        },
      );
    },
  );
}

Future<void> _savePartialSaleToCustomerLedger(BillingState billingState) async {
  if (_selectedCustomer == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un cliente para registrar el adeudo.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final total = billingState.totalAmount;
  final paidNow = _parseDouble(_partialPaidController.text);
  final pending = total - paidNow;
  final currentCustomer = _selectedCustomer!;
  final saleId = DateTime.now().millisecondsSinceEpoch.toString();
  final createdAt = DateTime.now();

  final openCycle = await _getOrCreateOpenDebtCycle(currentCustomer);

if (!mounted) return;

if (openCycle == null) {
  final originalProducts =
      billingState.cartItems.map((item) => item.product).toList();

  await _restoreStock(originalProducts);

  if (!mounted) return;

  setState(() {
    _isSavingSale = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No se pudo crear o recuperar el ciclo de adeudo.'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

  final sale = Sale(
    id: saleId,
    createdAt: createdAt,
    items: billingState.cartItems.map((item) {
      return SaleItem(
        productId: item.product.id,
        productName: item.product.name,
        internalCode: item.product.internalCode,
        barcode: item.product.barcode,
        imageUrl: item.product.imageUrl,
        localImagePath: item.product.localImagePath,
        unitType: item.product.unitType,
        quantity: item.quantity,
        unitPrice: item.product.price,
        total: item.total,
      );
    }).toList(),
    subtotal: total,
    discount: 0,
    total: total,
    paymentMethod: _paymentMethod,
    amountReceived: _paymentMethod == 'cash' ? paidNow : null,
    changeAmount: null,
    transferReference: _paymentMethod == 'transfer'
        ? (_transferReferenceController.text.trim().isEmpty
            ? null
            : _transferReferenceController.text.trim())
        : null,
    customerId: currentCustomer.id,
    customerName: currentCustomer.name,
    isCustomerLedger: true,
    isPartialCustomerLedger: true,
    paidAmount: paidNow,
    pendingAmount: pending,
  );

  final saleResult = await _salesRepository.saveSale(sale);

  if (!mounted) return;

  await saleResult.fold(
    (failure) async {
      final originalProducts =
          billingState.cartItems.map((item) => item.product).toList();

      await _restoreStock(originalProducts);

      if (!mounted) return;

      setState(() {
        _isSavingSale = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la venta parcial en historial: ${failure.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    },
    (_) async {
      final balanceAfter = currentCustomer.currentBalance + pending;

      final entry = CustomerLedgerEntry(
  id: '$saleId-ledger',
  customerId: currentCustomer.id,
  debtCycleId: openCycle.id,
  type: 'product_charge',
  createdAt: createdAt,
  description: 'Venta con pago parcial',
  amount: pending,
  balanceAfter: balanceAfter,
  relatedSaleId: saleId,
  items: billingState.cartItems.map((item) {
    return CustomerLedgerItem(
      productId: item.product.id,
      productName: item.product.name,
      internalCode: item.product.internalCode,
      barcode: item.product.barcode,
      imageUrl: item.product.imageUrl,
      localImagePath: item.product.localImagePath,
      quantity: item.quantity,
      unitPrice: item.product.price,
      total: item.total,
    );
  }).toList(),
  paymentSplits: const [],
);

      final ledgerResult = await _customerRepository.addCustomerLedgerEntry(
        entry,
      );

      if (!mounted) return;

      ledgerResult.fold(
        (failure) async {
          await HiveDatabase.saleBox.delete(saleId);

          final originalProducts =
              billingState.cartItems.map((item) => item.product).toList();
          await _restoreStock(originalProducts);

          if (!mounted) return;

          setState(() {
            _isSavingSale = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo guardar el pendiente en libreta: ${failure.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          setState(() {
            _isSavingSale = false;
          });

          context.read<ProductBloc>().add(LoadProducts());
          context.read<CustomerBloc>().add(const LoadCustomers());
          context.read<BillingBloc>().add(ClearCartEvent());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se cobraron ${_formatCurrency(paidNow)} y quedaron ${_formatCurrency(pending)} en la libreta de ${currentCustomer.name}.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          context.go('/');
        },
      );
    },
  );
}

Future<void> _selectCustomer() async {
  final customer = await context.push<Customer>('/customers/select');

  if (customer != null && mounted) {
    setState(() {
      _selectedCustomer = customer;
      _sendToCustomerLedger = true;
      _isPartialCustomerLedger = false;
      _partialPaidController.clear();
    });
  }
}

void _clearSelectedCustomer() {
  setState(() {
    _selectedCustomer = null;
    _sendToCustomerLedger = false;
    _isPartialCustomerLedger = false;
    _partialPaidController.clear();
  });
}

  Future<void> _confirmCancelSale() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancelar venta'),
          content: const Text(
            '¿Seguro que deseas cancelar esta venta? El carrito se vaciará.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sí, cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      context.read<BillingBloc>().add(ClearCartEvent());
      context.go('/');
    }
  }

Future<void> _confirmSale(BillingState billingState) async {

  if (_sendToCustomerLedger && _selectedCustomer == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un cliente para mandar la venta a libreta.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (billingState.cartItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay productos en la venta.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final stockError = _validateStockBeforeSale(billingState);
  if (stockError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(stockError),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final total = billingState.totalAmount;
  final amountReceived = _parseDouble(_amountReceivedController.text);
  final change = _calculateChange(total);

if (_sendToCustomerLedger && _isPartialCustomerLedger) {
  final paidNow = _parseDouble(_partialPaidController.text);

  if (_partialPaidController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingresa cuánto pagó el cliente ahora.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (paidNow <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pago parcial debe ser mayor a 0.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (paidNow >= total) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pago parcial debe ser menor al total de la venta.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
}

if (!_sendToCustomerLedger && _paymentMethod == 'cash') {
  if (_amountReceivedController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingresa el monto recibido.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (amountReceived < total) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El monto recibido no cubre el total de la venta.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
}

  setState(() {
    _isSavingSale = true;
  });

  final originalProducts =
      billingState.cartItems.map((item) => item.product).toList();

  final stockUpdateError = await _discountStock(billingState);

  if (!mounted) return;

  if (stockUpdateError != null) {
    setState(() {
      _isSavingSale = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo descontar el stock: $stockUpdateError'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

if (_sendToCustomerLedger && _isPartialCustomerLedger) {
  await _savePartialSaleToCustomerLedger(billingState);
  return;
}

if (_sendToCustomerLedger) {
  await _saveSaleToCustomerLedger(billingState);
  return;
}

  final sale = Sale(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
    items: billingState.cartItems.map((item) {
      return SaleItem(
        productId: item.product.id,
        productName: item.product.name,
        internalCode: item.product.internalCode,
        barcode: item.product.barcode,
        imageUrl: item.product.imageUrl,
        localImagePath: item.product.localImagePath,
        unitType: item.product.unitType,
        quantity: item.quantity,
        unitPrice: item.product.price,
        total: item.total,
      );
    }).toList(),
    subtotal: total,
    discount: 0,
    total: total,
    paymentMethod: _paymentMethod,
    amountReceived: _paymentMethod == 'cash' ? amountReceived : null,
    changeAmount: _paymentMethod == 'cash' ? change : null,
    transferReference: _paymentMethod == 'transfer'
        ? (_transferReferenceController.text.trim().isEmpty
            ? null
            : _transferReferenceController.text.trim())
        : null,
    customerId: null,
    customerName: null,
    isCustomerLedger: false,
    isPartialCustomerLedger: false,
    paidAmount: null,
    pendingAmount: null,
  );

  final result = await _salesRepository.saveSale(sale);

  if (!mounted) return;

  result.fold(
    (failure) async {
      await _restoreStock(originalProducts);

      if (!mounted) return;

      setState(() {
        _isSavingSale = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la venta: ${failure.message}'),
          backgroundColor: Colors.red,
        ),
      );
    },
(_) {
  setState(() {
    _isSavingSale = false;
  });

  context.read<ProductBloc>().add(LoadProducts());
  context.read<CustomerBloc>().add(const LoadCustomers());
  context.read<BillingBloc>().add(ClearCartEvent());

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Venta guardada y stock actualizado correctamente.'),
      backgroundColor: Colors.green,
    ),
  );

  context.go('/');
},
  );
}

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _transferReferenceController.dispose();
    _sheetExtent.dispose();
    _partialPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cobro',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _confirmCancelSale,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Cancelar venta',
          ),
        ],
      ),
      body: BlocBuilder<BillingBloc, BillingState>(
        builder: (context, billingState) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return ValueListenableBuilder<double>(
                valueListenable: _sheetExtent,
                builder: (context, extent, _) {
                  final bottomInset = (constraints.maxHeight * extent) + 24;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _buildProductsSummary(
                          billingState,
                          borderColor,
                          bottomInset: bottomInset,
                        ),
                      ),
                      _buildPaymentSheet(
                        billingState: billingState,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsSummary(
    BillingState billingState,
    Color borderColor, {
    double bottomInset = 0,
  }) {
    if (billingState.cartItems.isEmpty) {
      return const Center(
        child: Text('No hay productos en la venta.'),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildSectionHeader(
            title: 'Resumen de productos',
            subtitle: '${billingState.cartItems.length} líneas en la venta',
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + bottomInset,
              ),
              itemCount: billingState.cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = billingState.cartItems[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CheckoutThumbnail(
                        imageUrl: item.product.imageUrl,
                        localImagePath: item.product.localImagePath,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.product.brand?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.product.brand!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                _MiniInfoChip(
                                  label: 'Cantidad',
                                  value: '${item.quantity}',
                                ),
                                _MiniInfoChip(
                                  label: 'Precio',
                                  value: _formatCurrency(item.product.price),
                                ),
                                _MiniInfoChip(
                                  label: 'Subtotal',
                                  value: _formatCurrency(item.total),
                                  highlight: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSheet({
    required BillingState billingState,
  }) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final next = notification.extent;
        if ((next - _sheetExtent.value).abs() > 0.008) {
          _sheetExtent.value = next;
        }
        return true;
      },
      child: DraggableScrollableSheet(
initialChildSize: 0.54,
minChildSize: 0.10,
maxChildSize: 0.82,
snap: true,
snapSizes: const [0.10, 0.54, 0.82],        builder: (context, scrollController) {
          final extent = _sheetExtent.value;
final isHidden = extent <= 0.16;
final isSemi = extent > 0.16 && extent < 0.66;
final isFull = extent >= 0.66;
          final total = billingState.totalAmount;
          final totalItems = billingState.cartItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
          final change = _calculateChange(total);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      children: [
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedOpacity(
                          opacity: isHidden ? 1 : 0,
                          duration: const Duration(milliseconds: 140),
                          child: const Text(
                            'Desliza para ver cobro',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!isHidden)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
const Text(
  'Cobro',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  ),
),
if (isFull) ...[
  const SizedBox(height: 3),
  Text(
    '$totalItems artículos en la venta',
    style: TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    ),
  ),
],
const SizedBox(height: 14),
                            if (isFull) ...[
                              _summaryRow('Subtotal', _formatCurrency(total)),
                              const SizedBox(height: 8),
                              _summaryRow('Descuentos', _formatCurrency(0)),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                            ],

                            _summaryRow(
                              'Total a cobrar',
                              _formatCurrency(total),
                              isTotal: true,
                            ),

                            const SizedBox(height: 14),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE5E5EA)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Destino de la venta',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
ChoiceChip(
  label: const Text('Venta normal'),
  selected: !_sendToCustomerLedger,
  onSelected: (_) {
    setState(() {
      _sendToCustomerLedger = false;
      _selectedCustomer = null;
      _isPartialCustomerLedger = false;
      _partialPaidController.clear();
    });
  },
),
          ChoiceChip(
            label: const Text('Mandar a libreta'),
            selected: _sendToCustomerLedger,
            onSelected: (_) async {
              await _selectCustomer();
            },
          ),
        ],
      ),
if (_sendToCustomerLedger) ...[
  const SizedBox(height: 12),
  if (_selectedCustomer != null)
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente seleccionado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCustomer!.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_selectedCustomer!.phone != null &&
                    _selectedCustomer!.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedCustomer!.phone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelectedCustomer,
            icon: const Icon(Icons.close),
            tooltip: 'Quitar cliente',
          ),
        ],
      ),
    )
  else
    OutlinedButton.icon(
      onPressed: _selectCustomer,
      icon: const Icon(Icons.person_search_outlined),
      label: const Text('Seleccionar cliente'),
    ),
],
if (_sendToCustomerLedger && _selectedCustomer != null) ...[
  const SizedBox(height: 12),
  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      ChoiceChip(
        label: const Text('Adeudo completo'),
        selected: !_isPartialCustomerLedger,
        onSelected: (_) {
          setState(() {
            _isPartialCustomerLedger = false;
            _partialPaidController.clear();
          });
        },
      ),
      ChoiceChip(
        label: const Text('Pago parcial'),
        selected: _isPartialCustomerLedger,
        onSelected: (_) {
          setState(() {
            _isPartialCustomerLedger = true;
          });
        },
      ),
    ],
  ),
],
    ],
  ),
),

                            const SizedBox(height: 16),

if (!(_sendToCustomerLedger && !_isPartialCustomerLedger)) ...[
  if (isFull) ...[
    const Text(
      'Método de pago',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ChoiceChip(
          label: const Text('Efectivo'),
          selected: _paymentMethod == 'cash',
          onSelected: (_) {
            setState(() {
              _paymentMethod = 'cash';
            });
          },
        ),
        ChoiceChip(
          label: const Text('Transferencia'),
          selected: _paymentMethod == 'transfer',
          onSelected: (_) {
            setState(() {
              _paymentMethod = 'transfer';
            });
          },
        ),
        ChoiceChip(
          label: const Text('Tarjeta / Point'),
          selected: _paymentMethod == 'point',
          onSelected: (_) {
            setState(() {
              _paymentMethod = 'point';
            });
          },
        ),
      ],
    ),
    const SizedBox(height: 14),
  ] else ...[
    Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _paymentMethod == 'cash'
                  ? 'Método: Efectivo'
                  : _paymentMethod == 'transfer'
                      ? 'Método: Transferencia'
                      : 'Método: Tarjeta / Point',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
  ],
],

if (_sendToCustomerLedger && !_isPartialCustomerLedger) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Esta venta se registrará como adeudo completo en la libreta del cliente. En este paso no se cobrará monto recibido.',
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
      ),
    ),
  ),
] else if (_sendToCustomerLedger && _isPartialCustomerLedger) ...[
  TextField(
    controller: _partialPaidController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) => setState(() {}),
    decoration: const InputDecoration(
      labelText: 'Monto cobrado ahora',
      hintText: '0.00',
      prefixText: '\$ ',
    ),
  ),
  const SizedBox(height: 12),
  _summaryRow(
    'Se cobra ahora',
    _formatCurrency(_parseDouble(_partialPaidController.text)),
  ),
  const SizedBox(height: 8),
  _summaryRow(
    'Queda pendiente',
    _formatCurrency(_calculatePartialPending(total)),
    isTotal: true,
  ),
  if (_paymentMethod == 'transfer') ...[
    const SizedBox(height: 12),
    TextField(
      controller: _transferReferenceController,
      decoration: const InputDecoration(
        labelText: 'Referencia (opcional)',
        hintText: 'Ej. Folio o referencia',
      ),
    ),
  ] else if (_paymentMethod == 'point') ...[
    const SizedBox(height: 12),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'El monto capturado se tomará como lo cobrado ahora con terminal Point. El resto quedará pendiente en libreta.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
        ),
      ),
    ),
  ],
] else if (_paymentMethod == 'cash') ...[
  TextField(
    controller: _amountReceivedController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) => setState(() {}),
    decoration: const InputDecoration(
      labelText: 'Monto recibido',
      hintText: '0.00',
      prefixText: '\$ ',
    ),
  ),
  const SizedBox(height: 12),
  _summaryRow(
    'Cambio',
    change >= 0 ? _formatCurrency(change) : 'Pago incompleto',
    isTotal: change >= 0,
  ),
] else if (_paymentMethod == 'transfer') ...[
  if (isFull) ...[
    TextField(
      controller: _transferReferenceController,
      decoration: const InputDecoration(
        labelText: 'Referencia (opcional)',
        hintText: 'Ej. Folio o referencia',
      ),
    ),
  ] else ...[
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _transferReferenceController.text.trim().isEmpty
            ? 'Transferencia sin referencia'
            : 'Referencia: ${_transferReferenceController.text.trim()}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    ),
  ],
] else ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Cobro con terminal Point. La integración automática se agregará después. Por ahora esta opción solo registra la venta como pago con tarjeta.',
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
      ),
    ),
  ),
],

                            const SizedBox(height: 4),
                            PrimaryButton(
                              onPressed: _isSavingSale
                                  ? null
                                  : () => _confirmSale(
                                        context.read<BillingBloc>().state,
                                      ),
                              icon: _isSavingSale
                                  ? Icons.hourglass_top
                                  : Icons.check_circle_outline,
                              label: _isSavingSale
                                  ? 'Guardando venta...'
                                  : 'Confirmar venta',
                              isLoading: _isSavingSale,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 14,
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
      color: isTotal ? const Color(0xFF0F172A) : Colors.black87,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniInfoChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight
        ? AppTheme.primaryColor.withValues(alpha: 0.08)
        : Colors.grey.shade100;

    final textColor = highlight
        ? AppTheme.primaryColor
        : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;

  const _CheckoutThumbnail({
    required this.imageUrl,
    required this.localImagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.grey.shade400,
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
      ),
    );
  }
}