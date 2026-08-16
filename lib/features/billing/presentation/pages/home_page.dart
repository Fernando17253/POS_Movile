import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/domain/entities/product.dart';

import '../widgets/product_cards.dart';
import '../widgets/cart_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<double> _cartSheetExtent = ValueNotifier(0.10);

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartSheetExtent.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE BÚSQUEDA Y LÓGICA ---
  List<Product> _sortProductsForCatalog(List<Product> products) {
    final sorted = [...products];
    sorted.sort((a, b) {
      final aOut = a.stock <= 0;
      final bOut = b.stock <= 0;
      if (aOut != bOut) return aOut ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  String _translateBillingError(String error) {
    if (error.startsWith('Product not found')) return 'Producto no encontrado.';
    if (error.startsWith('Failed to auto-connect to printer')) return 'No se pudo conectar automáticamente a la impresora.';
    if (error.startsWith('Printer not connected')) return 'No hay impresora conectada ni guardada.';
    if (error.startsWith('Print failed')) return 'La impresión falló.';
    return error;
  }

  Future<void> _scanBarcode() async {
    final barcode = await context.push<String>('/scanner', extra: true); 
    
    if (barcode != null && barcode.isNotEmpty && mounted) {
      context.read<BillingBloc>().add(ScanBarcodeEvent(barcode));
    }
  }

  // --- VISTAS ---
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, marca, código...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 28),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close, size: 28),
                        tooltip: 'Limpiar búsqueda',
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 60,
            child: Material(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _scanBarcode,
                child: const Icon(
                  Icons.barcode_reader,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productos disponibles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca un producto para agregarlo al carrito',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                if (productState.status == ProductStatus.loading && productState.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (productState.products.isEmpty) {
                  return Center(
                    child: Text('No hay productos registrados.', style: Theme.of(context).textTheme.bodyLarge),
                  );
                }

                final filteredProducts = _sortProductsForCatalog(
                  productState.products.where((product) {
                    final query = _searchQuery;
                    return product.name.toLowerCase().contains(query) ||
                        (product.brand?.toLowerCase().contains(query) ?? false) ||
                        (product.barcode?.toLowerCase().contains(query) ?? false) ||
                        product.internalCode.toLowerCase().contains(query);
                  }).toList(),
                );

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text('No hay coincidencias.', style: Theme.of(context).textTheme.bodyLarge),
                  );
                }

                // NUEVO: Envolvemos las listas en el BillingBloc para reaccionar al Carrito en vivo
                return BlocBuilder<BillingBloc, BillingState>(
                  builder: (context, billingState) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid = constraints.maxWidth >= 720; // Modo Tablet

                        if (!useGrid) {
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              
                              // LÓGICA DE STOCK EN CARRITO
                              final cartQty = billingState.cartItems
                                  .where((item) => item.product.id == product.id)
                                  .fold<num>(0, (sum, item) => sum + item.quantity);
                              
                              final hasStockRemaining = product.stock > cartQty;

                              return Stack(
                                children: [
                                  // Tarjeta Original
                                  ProductListSaleCard(
                                    product: product,
                                    hasStock: hasStockRemaining,
                                  ),
                                  
                                  // Gafete Flotante de "En carrito"
                                  if (cartQty > 0)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          // Se pone naranja si hay stock, ROJO si ya te acabaste el stock
                                          color: hasStockRemaining ? Colors.orange.shade600 : Colors.red.shade700,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(14),
                                            bottomLeft: Radius.circular(14),
                                          ),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(-2, 2)),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              hasStockRemaining 
                                                  ? 'En carrito: ${cartQty % 1 == 0 ? cartQty.toInt() : cartQty.toStringAsFixed(2)}'
                                                  : 'Límite alcanzado ($cartQty)',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        }

                        // VISTA GRID PARA TABLETS
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                          itemCount: filteredProducts.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 280, 
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            
                            // LÓGICA DE STOCK EN CARRITO
                            final cartQty = billingState.cartItems
                                .where((item) => item.product.id == product.id)
                                .fold<num>(0, (sum, item) => sum + item.quantity);
                            
                            final hasStockRemaining = product.stock > cartQty;

                            return Stack(
                              children: [
                                ProductSaleCard(
                                  product: product,
                                  hasStock: hasStockRemaining,
                                ),
                                if (cartQty > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: hasStockRemaining ? Colors.orange.shade600 : Colors.red.shade700,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(14),
                                          bottomLeft: Radius.circular(14),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(-2, 2)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shopping_cart, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasStockRemaining 
                                                ? 'Llevas: ${cartQty % 1 == 0 ? cartQty.toInt() : cartQty.toStringAsFixed(2)}'
                                                : 'Agotado ($cartQty)',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abarrotes Primavera'), 
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: () => context.push('/sales'),
              icon: const Icon(Icons.history, size: 24),
              label: const Text(''),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings, size: 28),
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (previous, current) => previous.error != current.error && current.error != null,
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_translateBillingError(state.error!)),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listenWhen: (previous, current) => previous.message != current.message && current.message != null,
            listener: (context, state) {
              if (state.status == ProductStatus.error && state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopSection(),
                  Expanded(
                    child: _buildCatalogSection(),
                  ),
                ],
              ),
              CartBottomSheet(cartSheetExtent: _cartSheetExtent),
            ],
          ),
        ),
      ),
    );
  }
}