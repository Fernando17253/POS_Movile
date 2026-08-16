import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';

import '../widgets/product_widgets.dart'; // IMPORTAMOS LOS WIDGETS GIGANTES

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
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
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  String _formatStock(Product product) {
    if (product.stock % 1 == 0) {
      return product.stock.toInt().toString();
    }
    return product.stock.toStringAsFixed(2);
  }

  String _getUnitLabel(String unitType) {
    const units = {
      'piece': 'pieza',
      'kg': 'kg',
      'g': 'g',
      'lt': 'lt',
      'ml': 'ml',
      'pack': 'paquete',
      'box': 'caja',
    };
    return units[unitType] ?? unitType;
  }

  void _scanQR(List<Product> products) async {
    final barcode = await context.push<String>('/scanner');

    if (barcode == null || barcode.isEmpty) return;

    Product? matchedProduct;
    try {
      matchedProduct = products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      matchedProduct = null;
    }

    if (matchedProduct != null) {
      _searchController.text = matchedProduct.name;
    } else {
      _searchController.text = barcode;
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar Producto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: Text(
            '¿Seguro que deseas eliminar ${product.name} del catálogo?',
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<ProductBloc>().add(DeleteProduct(product.id));
    }
  }

  // ==========================================
  // LÓGICA DE REABASTECIMIENTO Y MERMA
  // ==========================================
  Future<void> _adjustStock(Product product, {required bool isAdding}) async {
    final TextEditingController qtyController = TextEditingController();
    
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isAdding ? 'Surtir Producto' : 'Registrar Merma',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 22,
              color: isAdding ? Colors.green.shade700 : Colors.orange.shade800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAdding 
                    ? '¿Cuántas unidades de "${product.name}" ingresaron al inventario?'
                    : '¿Cuántas unidades de "${product.name}" se dañaron o perdieron?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                autofocus: true,
                style: TextStyle(
                  fontSize: 42, 
                  fontWeight: FontWeight.w900, 
                  color: isAdding ? Colors.green.shade700 : Colors.orange.shade800
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: _getUnitLabel(product.unitType),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isAdding ? Colors.green : Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final qty = double.tryParse(qtyController.text.replaceAll(',', '.'));
                Navigator.pop(ctx, qty);
              },
              child: Text(
                isAdding ? 'Surtir' : 'Restar', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result > 0 && mounted) {
      double newStock = isAdding ? (product.stock + result) : (product.stock - result);
      
      // Evitamos que el stock quede en negativo si la merma es enorme
      if (newStock < 0) newStock = 0;

      final updatedProduct = product.copyWith(stock: newStock);
      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdding 
                ? '¡Se agregaron ${_formatStock(product.copyWith(stock: result))} al inventario!'
                : 'Se descontaron ${_formatStock(product.copyWith(stock: result))} por merma.',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: isAdding ? Colors.green : Colors.orange.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 36, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Buscador + Botón de Escáner Masivos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: InputDecoration(
                      hintText: 'Nombre, código...',
                      prefixIcon: const Icon(Icons.search, size: 32),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: const Icon(Icons.close, size: 32),
                              tooltip: 'Limpiar',
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: 68,
                      height: 68,
                      child: Material(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _scanQR(state.products),
                          child: const Icon(
                            Icons.barcode_reader,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state.status == ProductStatus.success && state.message != null) {
                  // Lo quitamos para no doble-notificar si fue actualización rápida de stock
                } else if (state.status == ProductStatus.error && state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!, style: const TextStyle(fontSize: 16)), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == ProductStatus.loading && state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  if (state.status == ProductStatus.error) {
                    return Center(child: Text('Error: ${state.message}', style: Theme.of(context).textTheme.titleLarge));
                  }
                  return const EmptyProductsState(hasSearch: false);
                }

                final filteredProducts = state.products.where((product) {
                  final query = _searchQuery;
                  return product.name.toLowerCase().contains(query) ||
                      (product.barcode?.toLowerCase().contains(query) ?? false) ||
                      (product.brand?.toLowerCase().contains(query) ?? false) ||
                      product.internalCode.toLowerCase().contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const EmptyProductsState(hasSearch: true);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), 
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    return ProductManagementCard(
                      product: product,
                      currencyText: _formatCurrency(product.price),
                      stockText: 'Stock: ${_formatStock(product)} ${_getUnitLabel(product.unitType)}',
                      onEdit: () => context.push('/products/edit/${product.id}', extra: product),
                      onDelete: () => _confirmDelete(product),
                      onRestock: () => _adjustStock(product, isAdding: true),
                      onWaste: () => _adjustStock(product, isAdding: false),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/barcode-entry'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 32),
        label: const Text('Nuevo Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}