import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/cart_item.dart';
import '../../../product/domain/entities/product.dart';

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

  String _translateBillingError(String error) {
    if (error.startsWith('Product not found')) {
      return 'Producto no encontrado.';
    }
    if (error.startsWith('Failed to auto-connect to printer')) {
      return 'No se pudo conectar automáticamente a la impresora.';
    }
    if (error.startsWith('Printer not connected')) {
      return 'No hay impresora conectada ni guardada.';
    }
    if (error.startsWith('Print failed')) {
      return 'La impresión falló.';
    }
    return error;
  }

  Future<void> _scanBarcode() async {
    final barcode = await context.push<String>('/scanner');

    if (barcode != null && barcode.isNotEmpty && mounted) {
      context.read<BillingBloc>().add(ScanBarcodeEvent(barcode));
    }
  }

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
                hintText: 'Buscar por nombre, marca, código o clave',
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: Material(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _scanBarcode,
                child: const Icon(
                  Icons.barcode_reader,
                  color: AppTheme.primaryColor,
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
          _buildSectionHeader(
            title: 'Productos disponibles',
            subtitle: 'Toca un producto para agregarlo al carrito',
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state.status == ProductStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  return const Center(
                    child: Text('No hay productos registrados.'),
                  );
                }

                final filteredProducts = state.products.where((product) {
                  final query = _searchQuery;

                  return product.name.toLowerCase().contains(query) ||
                      (product.brand?.toLowerCase().contains(query) ?? false) ||
                      (product.barcode?.toLowerCase().contains(query) ?? false) ||
                      product.internalCode.toLowerCase().contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay productos que coincidan con la búsqueda.',
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final useGrid = constraints.maxWidth >= 720;

                    if (!useGrid) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          return _ProductListSaleCard(
                            product: product,
                            currency: _formatCurrency(product.price),
                            stockText:
                                '${_formatStock(product)} ${_getUnitLabel(product.unitType)}',
                            onTap: () {
                              context.read<BillingBloc>().add(
                                    AddProductToCartEvent(product),
                                  );
                            },
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent:
                            248 +
                            ((MediaQuery.textScalerOf(context).scale(1) - 1) *
                                30),
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        return _ProductSaleCard(
                          product: product,
                          currency: _formatCurrency(product.price),
                          stockText:
                              '${_formatStock(product)} ${_getUnitLabel(product.unitType)}',
                          onTap: () {
                            context.read<BillingBloc>().add(
                                  AddProductToCartEvent(product),
                                );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCartSheet() {
  return NotificationListener<DraggableScrollableNotification>(
    onNotification: (notification) {
      final next = notification.extent;
      if ((next - _cartSheetExtent.value).abs() > 0.008) {
        _cartSheetExtent.value = next;
      }
      return true;
    },
    child: DraggableScrollableSheet(
      initialChildSize: 0.10,
      minChildSize: 0.10,
      maxChildSize: 0.82,
      snap: true,
      snapSizes: const [0.10, 0.45, 0.82],
      builder: (context, scrollController) {
        return ValueListenableBuilder<double>(
          valueListenable: _cartSheetExtent,
          builder: (context, extent, _) {
            final showContent = extent > 0.18;
            final showSummary = extent > 0.30;

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
              child: BlocBuilder<BillingBloc, BillingState>(
                builder: (context, state) {
                  final totalItems = state.cartItems.fold<int>(
                    0,
                    (sum, i) => sum + i.quantity,
                  );

                  return CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                              const SizedBox(height: 8),
                              AnimatedOpacity(
                                opacity: showContent ? 0 : 1,
                                duration: const Duration(milliseconds: 120),
                                child: const Text(
                                  'Desliza para ver carrito',
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

                      if (showContent)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Carrito',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalItems artículos',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (showContent)
                        SliverToBoxAdapter(
                          child: Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                        ),

                      if (showContent && state.cartItems.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyCart(),
                        ),

                      if (showContent && state.cartItems.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = state.cartItems[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildCartItemCard(context, item),
                                );
                              },
                              childCount: state.cartItems.length,
                            ),
                          ),
                        ),

                      if (showSummary)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _BottomInfoCard(
                                      label: 'Artículos',
                                      value: '$totalItems',
                                    ),
                                    _BottomInfoCard(
                                      label: 'Total',
                                      value: _formatCurrency(
                                        state.totalAmount,
                                      ),
                                      highlight: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PrimaryButton(
                                  onPressed: state.cartItems.isEmpty
                                      ? null
                                      : () => context.push('/checkout'),
                                  icon: Icons.point_of_sale,
                                  label: 'Cobrar',
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (!showContent)
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 8),
                        ),
                    ],
                  );
                },
              ),
            );
          },
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

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 38,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'El carrito está vacío',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanea un producto o selecciónalo desde la lista para comenzar la venta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    final imageUrl = item.product.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductThumbnail(imageUrl: imageUrl),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item.product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${_formatCurrency(item.total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityControl(
            quantity: item.quantity,
            onDecrease: () {
              if (item.quantity > 1) {
                context.read<BillingBloc>().add(
                      UpdateQuantityEvent(
                        item.product.id,
                        item.quantity - 1,
                      ),
                    );
              } else {
                context.read<BillingBloc>().add(
                      RemoveProductFromCartEvent(item.product.id),
                    );
              }
            },
            onIncrease: () {
              context.read<BillingBloc>().add(
                    UpdateQuantityEvent(
                      item.product.id,
                      item.quantity + 1,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
title: const Text(
    'Abarrotes Primavera',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22, // Un poco más grande se ve muy bien a la izquierda
    ),
  ),
  centerTitle: false, // <--- Esto lo mueve a la izquierda
  elevation: 0,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: () => context.push('/sales'),
        icon: const Icon(Icons.history, size: 20),
        label: const Text(
          '',
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
    IconButton(
      onPressed: () => context.push('/settings'),
      icon: const Icon(Icons.settings),
      tooltip: 'Configuración',
    ),
  ],
),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (previous, current) =>
                previous.error != current.error && current.error != null,
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_translateBillingError(state.error!)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listenWhen: (previous, current) =>
                previous.message != current.message && current.message != null,
            listener: (context, state) {
              if (state.status == ProductStatus.error &&
                  state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: Colors.red,
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
              _buildCartSheet(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _BottomInfoCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight
        ? AppTheme.primaryColor.withValues(alpha: 0.08)
        : Colors.grey.shade100;
    final foreground = highlight
        ? AppTheme.primaryColor
        : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: foreground.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallIconButton(
            icon: Icons.remove,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _SmallIconButton(
            icon: Icons.add,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class _ProductListSaleCard extends StatelessWidget {
  final Product product;
  final String currency;
  final String stockText;
  final VoidCallback onTap;

  const _ProductListSaleCard({
    required this.product,
    required this.currency,
    required this.stockText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductThumbnail(
              imageUrl: product.imageUrl,
              width: 64,
              height: 64,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (product.brand?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    currency,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stockText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.add_circle,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSaleCard extends StatelessWidget {
  final Product product;
  final String currency;
  final String stockText;
  final VoidCallback onTap;

  const _ProductSaleCard({
    required this.product,
    required this.currency,
    required this.stockText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductThumbnail(
              imageUrl: imageUrl,
              height: 92,
              width: double.infinity,
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            if (product.brand?.isNotEmpty ?? false)
              Text(
                product.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const Spacer(),
            Text(
              currency,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stockText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double width;

  const _ProductThumbnail({
    required this.imageUrl,
    this.height = 56,
    this.width = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        height: height,
        width: width,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: height,
            width: width,
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
}