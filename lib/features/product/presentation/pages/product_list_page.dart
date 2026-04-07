import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
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
        title: const Text(
          'Productos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nombre, marca, código o clave',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () => _scanQR(state.products),
                        padding: const EdgeInsets.all(15),
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
                if (state.status == ProductStatus.success &&
                    state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state.status == ProductStatus.error &&
                    state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == ProductStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  if (state.status == ProductStatus.error) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return const Center(
                    child: Text('No hay productos registrados.'),
                  );
                }

                final filteredProducts = state.products.where((product) {
                  final query = _searchQuery;

                  return product.name.toLowerCase().contains(query) ||
                      (product.barcode?.toLowerCase().contains(query) ?? false) ||
                      (product.brand?.toLowerCase().contains(query) ?? false) ||
                      product.internalCode.toLowerCase().contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No hay productos que coincidan.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 100,
                  ),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    return _ProductCard(
                      product: product,
                      borderColor: borderColor,
                      currency: _formatCurrency(product.price),
                      stockInfo:
                          'Stock: ${_formatStock(product)} ${_getUnitLabel(product.unitType)}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/barcode-entry'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final Color borderColor;
  final String currency;
  final String stockInfo;

  const _ProductCard({
    required this.product,
    required this.borderColor,
    required this.currency,
    required this.stockInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (product.brand?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.brand!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  currency,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stockInfo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clave: ${product.internalCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.barcode != null
                      ? 'Código: ${product.barcode}'
                      : 'Sin código de barras',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.barcode != null
                        ? Colors.grey[600]
                        : Colors.orange[700],
                    fontWeight: product.barcode != null
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ActionButtons(product: product),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Product product;

  const _ActionButtons({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit_rounded,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            context.push('/products/edit/${product.id}', extra: product);
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
          ),
          onPressed: () => _confirmDelete(context, product),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar'),
          content: Text('¿Deseas eliminar ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(product.id));
                Navigator.pop(ctx);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}