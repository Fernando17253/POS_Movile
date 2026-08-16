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
import '../widgets/checkout_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _amountReceivedController = TextEditingController();
  final TextEditingController _transferReferenceController = TextEditingController();
  final TextEditingController _partialPaidController = TextEditingController();

  final _customerRepository = CustomerRepositoryImpl();
  // FIX PANTALLA BLANCA: Ahora inicia sincronizado con el tamaño real inicial (0.54)
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.54); 
  final _salesRepository = SalesRepositoryImpl();
  final _productRepository = ProductRepositoryImpl();

  bool _isPartialCustomerLedger = false;
  String _paymentMethod = 'cash'; 
  bool _isSavingSale = false;

  Customer? _selectedCustomer;
  bool _sendToCustomerLedger = false;

  // --- LÓGICA DE NEGOCIO (MANTENIDA INTACTA) ---
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
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  String? _validateStockBeforeSale(BillingState billingState) {
    for (final item in billingState.cartItems) {
      final currentStock = item.product.stock;
      final requested = item.quantity.toDouble();
      if (currentStock <= 0) return 'El producto "${item.product.name}" no tiene stock disponible.';
      if (requested > currentStock) {
        return 'Stock insuficiente para "${item.product.name}". Disponible: ${_formatStockValue(currentStock)} | Intentas vender: ${item.quantity}.';
      }
    }
    return null;
  }

  Future<String?> _discountStock(BillingState billingState) async {
    final updatedOriginalProducts = <Product>[];
    for (final item in billingState.cartItems) {
      final originalProduct = item.product;
      final updatedProduct = originalProduct.copyWith(stock: originalProduct.stock - item.quantity);
      final result = await _productRepository.updateProduct(updatedProduct);
      bool failed = false;
      String failureMessage = '';
      result.fold((failure) { failed = true; failureMessage = failure.message; }, (_) {});
      if (failed) {
        for (final original in updatedOriginalProducts) await _productRepository.updateProduct(original);
        return failureMessage;
      }
      updatedOriginalProducts.add(originalProduct);
    }
    return null;
  }

  Future<void> _restoreStock(List<Product> originalProducts) async {
    for (final product in originalProducts) await _productRepository.updateProduct(product);
  }

  Future<CustomerDebtCycle?> _getOrCreateOpenDebtCycle(Customer customer) async {
    final openCycleResult = await _customerRepository.getOpenDebtCycle(customer.id);
    return await openCycleResult.fold((_) async => null, (existingCycle) async {
      if (existingCycle != null) return existingCycle;
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
      return saveResult.fold((_) => null, (_) => newCycle);
    });
  }

  Future<void> _saveSaleToCustomerLedger(BillingState billingState) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente para mandar la venta a libreta.'), backgroundColor: Colors.red));
      return;
    }
    final total = billingState.totalAmount;
    final currentCustomer = _selectedCustomer!;
    final saleId = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now();
    final openCycle = await _getOrCreateOpenDebtCycle(currentCustomer);

    if (!mounted) return;
    if (openCycle == null) {
      final originalProducts = billingState.cartItems.map((item) => item.product).toList();
      await _restoreStock(originalProducts);
      if (!mounted) return;
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo crear o recuperar el ciclo de adeudo.'), backgroundColor: Colors.red));
      return;
    }

    final sale = Sale(
      id: saleId,
      createdAt: createdAt,
      items: billingState.cartItems.map((item) => SaleItem(productId: item.product.id, productName: item.product.name, internalCode: item.product.internalCode, barcode: item.product.barcode, imageUrl: item.product.imageUrl, localImagePath: item.product.localImagePath, unitType: item.product.unitType, quantity: item.quantity, unitPrice: item.product.price, total: item.total)).toList(),
      subtotal: total, discount: 0, total: total, paymentMethod: 'customer_ledger', amountReceived: null, changeAmount: null, transferReference: null, customerId: currentCustomer.id, customerName: currentCustomer.name, isCustomerLedger: true, isPartialCustomerLedger: false, paidAmount: 0, pendingAmount: total,
    );

    final saleResult = await _salesRepository.saveSale(sale);
    if (!mounted) return;

    await saleResult.fold((failure) async {
      final originalProducts = billingState.cartItems.map((item) => item.product).toList();
      await _restoreStock(originalProducts);
      if (!mounted) return;
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar la venta en historial: ${failure.message}'), backgroundColor: Colors.red));
    }, (_) async {
      final balanceAfter = currentCustomer.currentBalance + total;
      final entry = CustomerLedgerEntry(id: '$saleId-ledger', customerId: currentCustomer.id, debtCycleId: openCycle.id, type: 'product_charge', createdAt: createdAt, description: 'Venta enviada a libreta', amount: total, balanceAfter: balanceAfter, relatedSaleId: saleId, items: billingState.cartItems.map((item) => CustomerLedgerItem(productId: item.product.id, productName: item.product.name, internalCode: item.product.internalCode, barcode: item.product.barcode, imageUrl: item.product.imageUrl, localImagePath: item.product.localImagePath, quantity: item.quantity, unitPrice: item.product.price, total: item.total)).toList(), paymentSplits: const []);
      
      final ledgerResult = await _customerRepository.addCustomerLedgerEntry(entry);
      if (!mounted) return;

      ledgerResult.fold((failure) async {
        await HiveDatabase.saleBox.delete(saleId);
        final originalProducts = billingState.cartItems.map((item) => item.product).toList();
        await _restoreStock(originalProducts);
        if (!mounted) return;
        setState(() => _isSavingSale = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar la libreta: ${failure.message}'), backgroundColor: Colors.red));
      }, (_) {
        setState(() => _isSavingSale = false);
        context.read<ProductBloc>().add(LoadProducts());
        context.read<CustomerBloc>().add(const LoadCustomers());
        context.read<BillingBloc>().add(ClearCartEvent());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Venta enviada a la libreta de ${currentCustomer.name}.'), backgroundColor: Colors.green));
        context.go('/');
      });
    });
  }

  Future<void> _savePartialSaleToCustomerLedger(BillingState billingState) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente.'), backgroundColor: Colors.red));
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
      final originalProducts = billingState.cartItems.map((item) => item.product).toList();
      await _restoreStock(originalProducts);
      if (!mounted) return;
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al obtener ciclo.'), backgroundColor: Colors.red));
      return;
    }

    final sale = Sale(
      id: saleId, createdAt: createdAt,
      items: billingState.cartItems.map((item) => SaleItem(productId: item.product.id, productName: item.product.name, internalCode: item.product.internalCode, barcode: item.product.barcode, imageUrl: item.product.imageUrl, localImagePath: item.product.localImagePath, unitType: item.product.unitType, quantity: item.quantity, unitPrice: item.product.price, total: item.total)).toList(),
      subtotal: total, discount: 0, total: total, paymentMethod: _paymentMethod, amountReceived: _paymentMethod == 'cash' ? paidNow : null, changeAmount: null, transferReference: _paymentMethod == 'transfer' ? (_transferReferenceController.text.trim().isEmpty ? null : _transferReferenceController.text.trim()) : null, customerId: currentCustomer.id, customerName: currentCustomer.name, isCustomerLedger: true, isPartialCustomerLedger: true, paidAmount: paidNow, pendingAmount: pending,
    );

    final saleResult = await _salesRepository.saveSale(sale);
    if (!mounted) return;

    await saleResult.fold((failure) async {
      final originalProducts = billingState.cartItems.map((item) => item.product).toList();
      await _restoreStock(originalProducts);
      if (!mounted) return;
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red));
    }, (_) async {
      final balanceAfter = currentCustomer.currentBalance + pending;
      final entry = CustomerLedgerEntry(id: '$saleId-ledger', customerId: currentCustomer.id, debtCycleId: openCycle.id, type: 'product_charge', createdAt: createdAt, description: 'Venta con pago parcial', amount: pending, balanceAfter: balanceAfter, relatedSaleId: saleId, items: billingState.cartItems.map((item) => CustomerLedgerItem(productId: item.product.id, productName: item.product.name, internalCode: item.product.internalCode, barcode: item.product.barcode, imageUrl: item.product.imageUrl, localImagePath: item.product.localImagePath, quantity: item.quantity, unitPrice: item.product.price, total: item.total)).toList(), paymentSplits: const []);
      
      final ledgerResult = await _customerRepository.addCustomerLedgerEntry(entry);
      if (!mounted) return;

      ledgerResult.fold((failure) async {
        await HiveDatabase.saleBox.delete(saleId);
        final originalProducts = billingState.cartItems.map((item) => item.product).toList();
        await _restoreStock(originalProducts);
        if (!mounted) return;
        setState(() => _isSavingSale = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red));
      }, (_) {
        setState(() => _isSavingSale = false);
        context.read<ProductBloc>().add(LoadProducts());
        context.read<CustomerBloc>().add(const LoadCustomers());
        context.read<BillingBloc>().add(ClearCartEvent());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Se cobraron ${_formatCurrency(paidNow)} y restan ${_formatCurrency(pending)}.'), backgroundColor: Colors.green));
        context.go('/');
      });
    });
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
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: const Text('¿Seguro que deseas cancelar esta venta? El carrito se vaciará.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldCancel == true && mounted) {
      context.read<BillingBloc>().add(ClearCartEvent());
      context.go('/');
    }
  }

  Future<void> _confirmSale(BillingState billingState) async {
    if (_sendToCustomerLedger && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente.'), backgroundColor: Colors.red));
      return;
    }
    if (billingState.cartItems.isEmpty) return;

    final stockError = _validateStockBeforeSale(billingState);
    if (stockError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stockError), backgroundColor: Colors.red));
      return;
    }

    final total = billingState.totalAmount;
    final amountReceived = _parseDouble(_amountReceivedController.text);
    final change = _calculateChange(total);

    if (_sendToCustomerLedger && _isPartialCustomerLedger) {
      final paidNow = _parseDouble(_partialPaidController.text);
      if (_partialPaidController.text.trim().isEmpty || paidNow <= 0 || paidNow >= total) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto parcial válido mayor a 0 y menor al total.'), backgroundColor: Colors.red));
        return;
      }
    }

    if (!_sendToCustomerLedger && _paymentMethod == 'cash') {
      if (_amountReceivedController.text.trim().isEmpty || amountReceived < total) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto recibido inválido o insuficiente.'), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isSavingSale = true);
    final originalProducts = billingState.cartItems.map((item) => item.product).toList();
    final stockUpdateError = await _discountStock(billingState);
    
    if (!mounted) return;
    if (stockUpdateError != null) {
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error stock: $stockUpdateError'), backgroundColor: Colors.red));
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
      items: billingState.cartItems.map((item) => SaleItem(productId: item.product.id, productName: item.product.name, internalCode: item.product.internalCode, barcode: item.product.barcode, imageUrl: item.product.imageUrl, localImagePath: item.product.localImagePath, unitType: item.product.unitType, quantity: item.quantity, unitPrice: item.product.price, total: item.total)).toList(),
      subtotal: total, discount: 0, total: total, paymentMethod: _paymentMethod, amountReceived: _paymentMethod == 'cash' ? amountReceived : null, changeAmount: _paymentMethod == 'cash' ? change : null, transferReference: _paymentMethod == 'transfer' ? (_transferReferenceController.text.trim().isEmpty ? null : _transferReferenceController.text.trim()) : null, customerId: null, customerName: null, isCustomerLedger: false, isPartialCustomerLedger: false, paidAmount: null, pendingAmount: null,
    );

    final result = await _salesRepository.saveSale(sale);
    if (!mounted) return;

    result.fold((failure) async {
      await _restoreStock(originalProducts);
      if (!mounted) return;
      setState(() => _isSavingSale = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red));
    }, (_) {
      setState(() => _isSavingSale = false);
      context.read<ProductBloc>().add(LoadProducts());
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<BillingBloc>().add(ClearCartEvent());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta completada.'), backgroundColor: Colors.green));
      context.go('/');
    });
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _transferReferenceController.dispose();
    _sheetExtent.dispose();
    _partialPaidController.dispose();
    super.dispose();
  }

  // ==============================================================
  // VISTAS REFACTORIZADAS (Sin Lag y con renderizado incondicional)
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobro de Venta'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 32, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _confirmCancelSale,
            icon: const Icon(Icons.delete_outline, size: 30),
            tooltip: 'Cancelar venta',
          ),
        ],
      ),
      body: BlocBuilder<BillingBloc, BillingState>(
        builder: (context, billingState) {
          // FIX LAG: Quitamos el ValueListenableBuilder del Stack padre.
          // Ahora el fondo se pinta 1 sola vez y el BottomSheet sube ágilmente.
          final screenHeight = MediaQuery.of(context).size.height;

          return Stack(
            children: [
              Positioned.fill(
                // Dejamos un espacio fijo abajo (55% de pantalla) para que la lista de
                // productos no quede tapada y siempre puedas scrollear.
                child: _buildProductsSummary(billingState, bottomInset: screenHeight * 0.55),
              ),
              _buildPaymentSheet(billingState: billingState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductsSummary(BillingState billingState, {double bottomInset = 0}) {
    if (billingState.cartItems.isEmpty) {
      return Center(
        child: Text('No hay productos en la venta.', style: Theme.of(context).textTheme.titleLarge),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Resumen de la orden', style: Theme.of(context).textTheme.titleLarge),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
              itemCount: billingState.cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = billingState.cartItems[index];
                return CheckoutItemCard(
                  item: item,
                  formattedPrice: _formatCurrency(item.product.price),
                  formattedTotal: _formatCurrency(item.total),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSheet({required BillingState billingState}) {
    final theme = Theme.of(context);
    final total = billingState.totalAmount;
    final totalItems = billingState.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final change = _calculateChange(total);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final next = notification.extent;
        if ((next - _sheetExtent.value).abs() > 0.008) _sheetExtent.value = next;
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.54, // Empieza a la mitad
        minChildSize: 0.10,
        maxChildSize: 0.88,
        snap: true,
        // FIX APERTURA RÁPIDA: Quitamos los puntos intermedios. Solo hay abajo (0.10), inicial (0.54) y abierto 100% (0.88).
        snapSizes: const [0.10, 0.54, 0.88],
        builder: (context, scrollController) {
          
          // FIX PANTALLA BLANCA & LAG: Ya no ocultamos contenido con `if (!isHidden)`. 
          // Construimos TODO de inmediato. El DraggableScrollableSheet se encargará
          // de ocultarlo naturalmente debajo del límite de la pantalla. ¡Adiós al lag!
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, -4))],
            ),
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 46, height: 6,
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Opciones de Pago', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        
                        // Mostramos el resumen limpio arriba siempre
                        Text('$totalItems artículos en total', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        SummaryRow(label: 'Total a cobrar', value: _formatCurrency(total), isTotal: true),
                        const Divider(height: 32),

                        // --- SECCIÓN: DESTINO DE VENTA ---
                        Text('Destino de la venta', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12, runSpacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Venta Normal'),
                              selected: !_sendToCustomerLedger,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              labelStyle: theme.textTheme.bodyLarge?.copyWith(color: !_sendToCustomerLedger ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() {
                                _sendToCustomerLedger = false; _selectedCustomer = null; _isPartialCustomerLedger = false; _partialPaidController.clear();
                              }),
                            ),
                            ChoiceChip(
                              label: const Text('Libreta / Fiado'),
                              selected: _sendToCustomerLedger,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              labelStyle: theme.textTheme.bodyLarge?.copyWith(color: _sendToCustomerLedger ? Colors.white : Colors.black87),
                              onSelected: (_) => _selectCustomer(),
                            ),
                          ],
                        ),

                        if (_sendToCustomerLedger) ...[
                          const SizedBox(height: 16),
                          if (_selectedCustomer != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: theme.primaryColor, size: 36),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cliente vinculado', style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                        Text(_selectedCustomer!.name, style: theme.textTheme.titleMedium),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _clearSelectedCustomer,
                                    icon: const Icon(Icons.close, size: 28),
                                  )
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _selectCustomer,
                              icon: const Icon(Icons.person_search_outlined, size: 28),
                              label: const Text('Asignar Cliente'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: theme.textTheme.bodyLarge),
                            ),

                          if (_selectedCustomer != null) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: [
                                ChoiceChip(
                                  label: const Text('Adeudar Todo'),
                                  selected: !_isPartialCustomerLedger,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  labelStyle: theme.textTheme.bodyLarge?.copyWith(color: !_isPartialCustomerLedger ? Colors.white : Colors.black87),
                                  onSelected: (_) => setState(() { _isPartialCustomerLedger = false; _partialPaidController.clear(); }),
                                ),
                                ChoiceChip(
                                  label: const Text('Pago Parcial'),
                                  selected: _isPartialCustomerLedger,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  labelStyle: theme.textTheme.bodyLarge?.copyWith(color: _isPartialCustomerLedger ? Colors.white : Colors.black87),
                                  onSelected: (_) => setState(() => _isPartialCustomerLedger = true),
                                ),
                              ],
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),

                        // --- SECCIÓN: MÉTODOS DE PAGO ---
                        if (!(_sendToCustomerLedger && !_isPartialCustomerLedger)) ...[
                          Text('Método de pago', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12, runSpacing: 12,
                            children: [
                              ChoiceChip(
                                label: const Text('Efectivo'),
                                selected: _paymentMethod == 'cash',
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(color: _paymentMethod == 'cash' ? Colors.white : Colors.black87),
                                onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                              ),
                              ChoiceChip(
                                label: const Text('Transferencia'),
                                selected: _paymentMethod == 'transfer',
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(color: _paymentMethod == 'transfer' ? Colors.white : Colors.black87),
                                onSelected: (_) => setState(() => _paymentMethod = 'transfer'),
                              ),
                              ChoiceChip(
                                label: const Text('Tarjeta/Point'),
                                selected: _paymentMethod == 'point',
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(color: _paymentMethod == 'point' ? Colors.white : Colors.black87),
                                onSelected: (_) => setState(() => _paymentMethod = 'point'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- SECCIÓN: INPUTS FINALES DE COBRO ---
                        if (_sendToCustomerLedger && !_isPartialCustomerLedger)
                          InfoAlertCard.warning(text: 'Se enviará el 100% de esta venta a la libreta del cliente. No se registrará ingreso de dinero hoy.')
                        else if (_sendToCustomerLedger && _isPartialCustomerLedger) ...[
                          TextField(
                            controller: _partialPaidController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: theme.textTheme.titleLarge,
                            decoration: const InputDecoration(labelText: 'Abono Inicial (Cobrado Ahora)', hintText: '0.00', prefixText: '\$ '),
                          ),
                          const SizedBox(height: 16),
                          SummaryRow(label: 'Se anota en libreta', value: _formatCurrency(_calculatePartialPending(total)), isTotal: true),
                          if (_paymentMethod == 'transfer') ...[
                            const SizedBox(height: 16),
                            TextField(controller: _transferReferenceController, decoration: const InputDecoration(labelText: 'Referencia (Opcional)', hintText: 'Folio')),
                          ] else if (_paymentMethod == 'point') ...[
                            const SizedBox(height: 16),
                            InfoAlertCard.info(text: 'El abono se registrará como pagado con tarjeta/terminal. El resto irá a libreta.'),
                          ],
                        ] else if (_paymentMethod == 'cash') ...[
                          TextField(
                            controller: _amountReceivedController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: theme.textTheme.displayMedium,
                            decoration: const InputDecoration(labelText: 'Monto recibido del cliente', hintText: '0.00', prefixText: '\$ '),
                          ),
                          const SizedBox(height: 16),
                          SummaryRow(
                            label: 'Cambio a entregar',
                            value: change >= 0 ? _formatCurrency(change) : 'Falta dinero',
                            isTotal: true,
                          ),
                        ] else if (_paymentMethod == 'transfer') ...[
                          TextField(
                            controller: _transferReferenceController,
                            style: theme.textTheme.bodyLarge,
                            decoration: const InputDecoration(labelText: 'Número de Referencia (Opcional)', hintText: 'Ej. 0123456'),
                          ),
                        ] else ...[
                          InfoAlertCard.info(text: 'Cobra desde tu terminal y presiona confirmar para guardar la venta.'),
                        ],

                        const SizedBox(height: 24),
                        
                        // --- BOTÓN PRINCIPAL ---
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            onPressed: _isSavingSale ? null : () => _confirmSale(billingState),
                            icon: _isSavingSale ? Icons.hourglass_top : Icons.check_circle,
                            label: _isSavingSale ? 'Guardando Venta...' : 'CONFIRMAR Y COBRAR',
                            isLoading: _isSavingSale,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}