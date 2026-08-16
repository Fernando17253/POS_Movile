import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/billing_bloc.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import 'product_cards.dart'; // Para reutilizar el ProductThumbnail

// Helper local para moneda
String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(2)} MXN';
}

class CartBottomSheet extends StatelessWidget {
  final ValueNotifier<double> cartSheetExtent;

  const CartBottomSheet({
    super.key,
    required this.cartSheetExtent,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final next = notification.extent;
        if ((next - cartSheetExtent.value).abs() > 0.008) {
          cartSheetExtent.value = next;
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.10,
        minChildSize: 0.10,
        maxChildSize: 0.88, // Ajustado para que se abra casi al máximo de la pantalla
        snap: true,
        // FIX DE APERTURA: Solo 2 paradas. Abajo (0.10) y abierto por completo (0.88)
        snapSizes: const [0.10, 0.88], 
        builder: (context, scrollController) {
          
          // FIX DE LAG: Eliminamos el ValueListenableBuilder que envolvía a todo.
          // Ahora dibujamos toda la interfaz de un solo golpe. El DraggableScrollableSheet
          // se encargará de mostrar u ocultar la capa rápidamente sin reconstruir widgets.
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  0, (sum, i) => sum + i.quantity,
                );

                return CustomScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // Mango para deslizar (Drag handle)
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Column(
                          children: [
                            Container(
                              width: 46,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Aquí SÍ usamos ValueListenableBuilder porque solo vamos a animar este simple texto
                            ValueListenableBuilder<double>(
                              valueListenable: cartSheetExtent,
                              builder: (context, extent, child) {
                                return AnimatedOpacity(
                                  opacity: extent > 0.18 ? 0 : 1,
                                  duration: const Duration(milliseconds: 120),
                                  child: Text(
                                    'Desliza hacia arriba para ver carrito',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Encabezado del carrito (Renderizado Incondicional)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Carrito de Venta', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text('$totalItems artículos', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: Divider(height: 1, color: Colors.grey.shade300)),

                    // Estado Vacío
                    if (state.cartItems.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: CartEmptyView(),
                      ),

                    // Lista de Artículos
                    if (state.cartItems.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = state.cartItems[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CartItemCard(item: item),
                              );
                            },
                            childCount: state.cartItems.length,
                          ),
                        ),
                      ),

                    // Panel Inferior de Cobro (Renderizado Incondicional)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: BottomInfoCard(
                                    label: 'Artículos',
                                    value: '$totalItems',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: BottomInfoCard(
                                    label: 'Total a Cobrar',
                                    value: _formatCurrency(state.totalAmount),
                                    highlight: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                onPressed: state.cartItems.isEmpty
                                    ? null
                                    : () => context.push('/checkout'),
                                icon: Icons.point_of_sale,
                                label: 'Cobrar Venta',
                              ),
                            ),
                            const SizedBox(height: 24), // Espacio para el SafeArea nativo del teléfono
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// COMPONENTES INTERNOS DEL CARRITO
// ==========================================

class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canIncrease = (item.quantity + 1) <= item.product.stock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProductThumbnail(
            imageUrl: item.product.imageUrl,
            localImagePath: item.product.localImagePath,
            width: 64,
            height: 64,
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
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item.product.price),
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Subtotal: ${_formatCurrency(item.total)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityControl(
            quantity: item.quantity,
            canIncrease: canIncrease,
            onDecrease: () {
              if (item.quantity > 1) {
                context.read<BillingBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity - 1));
              } else {
                context.read<BillingBloc>().add(RemoveProductFromCartEvent(item.product.id));
              }
            },
            onIncrease: canIncrease
                ? () => context.read<BillingBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity + 1))
                : null,
          ),
        ],
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CartButton(icon: Icons.add, onTap: onIncrease, enabled: canIncrease),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _CartButton(icon: Icons.remove, onTap: onDecrease, enabled: true),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _CartButton({required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? AppTheme.primaryColor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class BottomInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const BottomInfoCard({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100;
    final foreground = highlight ? AppTheme.primaryColor : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: foreground.withValues(alpha: 0.8), letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: foreground, fontSize: highlight ? 26 : 22),
            ),
          ),
        ],
      ),
    );
  }
}

class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text('El carrito está vacío', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Escanea un producto o selecciónalo desde la lista para comenzar la venta.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}