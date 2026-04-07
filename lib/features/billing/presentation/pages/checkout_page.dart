import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';

import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
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
      body: BlocConsumer<BillingBloc, BillingState>(
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
        builder: (context, billingState) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final floatingCardWidth = isWide ? 340.0 : constraints.maxWidth - 24;
              final rightInsetForList = isWide ? floatingCardWidth + 32 : 0.0;
              final bottomInsetForList = isWide ? 16.0 : 250.0;

              return Stack(
                children: [
                  Positioned.fill(
                    child: _buildProductsSummary(
                      billingState,
                      borderColor,
                      rightInset: rightInsetForList,
                      bottomInset: bottomInsetForList,
                    ),
                  ),
                  if (isWide)
                    Positioned(
                      top: 16,
                      right: 16,
                      width: floatingCardWidth,
                      child: _buildFloatingTotalsCard(billingState),
                    )
                  else
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: SafeArea(
                        top: false,
                        child: _buildFloatingTotalsCard(billingState),
                      ),
                    ),
                ],
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
    double rightInset = 0,
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
                16 + rightInset,
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
                      _CheckoutThumbnail(imageUrl: item.product.imageUrl),
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

  Widget _buildFloatingTotalsCard(BillingState billingState) {
    final subtotal = billingState.totalAmount;
    final total = billingState.totalAmount;
    final totalItems = billingState.cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$totalItems artículos en la venta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 14),
            _summaryRow('Subtotal', _formatCurrency(subtotal)),
            const SizedBox(height: 8),
            _summaryRow('Descuentos', _formatCurrency(0)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _summaryRow(
              'Total a cobrar',
              _formatCurrency(total),
              isTotal: true,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'El ticket y los datos de la tienda se generarán desde el historial de ventas.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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

  const _CheckoutThumbnail({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
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
}