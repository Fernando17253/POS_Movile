import 'package:billing_app/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:billing_app/features/sales/domain/entities/sale.dart';
import 'package:billing_app/features/sales/domain/entities/sale_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/primary_button.dart';

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

  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.10);
  final _salesRepository = SalesRepositoryImpl();

  String _paymentMethod = 'cash'; // cash | transfer
  bool _isSavingSale = false;

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _calculateChange(double total) {
    if (_paymentMethod != 'cash') return 0;
    final received = _parseDouble(_amountReceivedController.text);
    return received - total;
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
    if (billingState.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos en la venta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final total = billingState.totalAmount;
    final amountReceived = _parseDouble(_amountReceivedController.text);
    final change = _calculateChange(total);

    if (_paymentMethod == 'cash') {
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
    );

    final result = await _salesRepository.saveSale(sale);

    if (!mounted) return;

    setState(() {
      _isSavingSale = false;
    });

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar la venta: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        context.read<BillingBloc>().add(ClearCartEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta guardada correctamente.'),
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

                            const SizedBox(height: 16),

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

if (_paymentMethod == 'cash') ...[
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