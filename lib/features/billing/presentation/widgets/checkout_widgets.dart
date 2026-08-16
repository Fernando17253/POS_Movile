import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cart_item.dart';
import 'product_cards.dart'; // Reutilizamos el ProductThumbnail

// ==========================================
// FILA DE TOTALES Y RESUMEN (FittedBox para evitar overflow)
// ==========================================
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = isTotal 
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryColor)
        : theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[800]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          const SizedBox(width: 16),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA DE PRODUCTO EN EL RESUMEN DE COBRO
// ==========================================
class CheckoutItemCard extends StatelessWidget {
  final CartItem item;
  final String formattedPrice;
  final String formattedTotal;

  const CheckoutItemCard({
    super.key,
    required this.item,
    required this.formattedPrice,
    required this.formattedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumbnail(
            imageUrl: item.product.imageUrl,
            localImagePath: item.product.localImagePath,
            width: 68,
            height: 68,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (item.product.brand?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.product.brand!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniInfoChip(label: 'Cant.', value: '${item.quantity}'),
                    _MiniInfoChip(label: 'Precio', value: formattedPrice),
                    _MiniInfoChip(label: 'Subtotal', value: formattedTotal, highlight: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniInfoChip({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100;
    final textColor = highlight ? AppTheme.primaryColor : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETAS DE INFORMACIÓN Y ALERTAS
// ==========================================
class InfoAlertCard extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const InfoAlertCard({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  factory InfoAlertCard.warning({required String text}) {
    return InfoAlertCard(
      text: text,
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      textColor: Colors.orange.shade800,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory InfoAlertCard.info({required String text}) {
    return InfoAlertCard(
      text: text,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      textColor: AppTheme.primaryColor,
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}