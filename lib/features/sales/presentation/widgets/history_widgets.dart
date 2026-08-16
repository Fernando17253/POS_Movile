import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sale.dart';
import '../../../customers/domain/entities/customer_debt_cycle.dart';
import '../../../customers/domain/entities/customer_ledger_entry.dart';

// ==========================================
// HELPERS COMPARTIDOS
// ==========================================
String two(int n) => n.toString().padLeft(2, '0');
String formatCurrency(double value) => '\$${value.toStringAsFixed(2)} MXN';
String formatDate(DateTime date) => '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
String buildSaleFolio(Sale sale) => 'VTA-${sale.createdAt.year}${two(sale.createdAt.month)}${two(sale.createdAt.day)}-${sale.id.length > 6 ? sale.id.substring(sale.id.length - 6) : sale.id}';
String paymentMethodLabel(String method) => {'cash': 'Efectivo', 'transfer': 'Transferencia', 'point': 'Tarjeta / Point', 'customer_ledger': 'Libreta'}[method] ?? method;
Color paymentMethodColor(String method) => {'cash': Colors.green, 'transfer': Colors.blue, 'point': Colors.deepPurple, 'customer_ledger': Colors.orange}[method] ?? Colors.grey;
String ledgerEntryTypeLabel(String type) => {'manual_charge': 'Cargo manual', 'product_charge': 'Cargo por productos', 'payment': 'Abono', 'settlement': 'Liquidación'}[type] ?? type;

// ==========================================
// TARJETA DE VENTA NORMAL
// ==========================================
class HistoryNormalSaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const HistoryNormalSaleCard({super.key, required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsCount = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
                  child: Text(buildSaleFolio(sale), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: paymentMethodColor(sale.paymentMethod).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                  child: Text(paymentMethodLabel(sale.paymentMethod), style: TextStyle(color: paymentMethodColor(sale.paymentMethod), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(formatDate(sale.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (sale.customerName?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text('Cliente: ${sale.customerName!}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                HistoryInfoChip(label: 'Artículos', value: '$itemsCount'),
                HistoryInfoChip(label: 'Total', value: formatCurrency(sale.total), highlight: true),
              ],
            ),
            if (sale.transferReference?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text('Referencia: ${sale.transferReference!}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.items.take(2).map((e) => e.productName).join(', '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TARJETA DE ADEUDO (LIBRETA)
// ==========================================
class HistoryDebtCycleCard extends StatelessWidget {
  final CustomerDebtCycle cycle;
  final List<CustomerLedgerEntry> entries;
  final VoidCallback onTap;

  const HistoryDebtCycleCard({super.key, required this.cycle, required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = entries.fold<int>(0, (sum, entry) => sum + entry.items.fold<int>(0, (iSum, item) => iSum + item.quantity));
    final productNames = {for (final entry in entries) ...entry.items.map((item) => item.productName)}.toList();
    final previewProducts = productNames.take(3).join(', ');
    final remainingProducts = productNames.length - 3;
    final subtitleProducts = previewProducts.isEmpty ? 'Sin productos visibles' : remainingProducts > 0 ? '$previewProducts +$remainingProducts más' : previewProducts;
    
    final partialSalesCount = entries.where((entry) => entry.type == 'product_charge' && entry.description.toLowerCase().contains('parcial')).length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Libreta / Adeudo', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: cycle.isClosed ? Colors.green.withValues(alpha: 0.10) : Colors.red.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                  child: Text(cycle.isClosed ? 'Liquidado' : 'Abierto', style: TextStyle(color: cycle.isClosed ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                if (partialSalesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                    child: Text('$partialSalesCount pago parcial', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
            ],
            ),
            const SizedBox(height: 12),
            Text(cycle.customerNameSnapshot, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Inicio: ${formatDate(cycle.openedAt)}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            if (cycle.closedAt != null) ...[
              const SizedBox(height: 4),
              Text('Cierre: ${formatDate(cycle.closedAt!)}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                HistoryInfoChip(label: 'Adeudado', value: formatCurrency(cycle.totalCharged), highlight: true),
                HistoryInfoChip(label: 'Abonado', value: formatCurrency(cycle.totalPaid)),
                HistoryInfoChip(label: 'Artículos', value: '$totalItems'),
              ],
            ),
            const SizedBox(height: 12),
            Text(subtitleProducts, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            const Row(children: [Spacer(), Icon(Icons.chevron_right, color: Colors.grey)]),
          ],
        ),
      ),
    );
  }
}

// ... AQUÍ DEBAJO QUEDAN TUS WIDGETS QUE YA ESTABAN: 
// HistorySummaryCard, HistoryInfoChip, SaleDetailThumbnail, TicketRow
// (Mantenlos tal cual te los pasé en la respuesta anterior)

class HistorySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const HistorySummaryCard({super.key, required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white;
    final foreground = highlight ? AppTheme.primaryColor : Colors.grey.shade900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: foreground.withValues(alpha: 0.7), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: foreground))),
        ],
      ),
    );
  }
}

class HistoryInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const HistoryInfoChip({super.key, required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100;
    final foreground = highlight ? AppTheme.primaryColor : Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: foreground.withValues(alpha: 0.8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: foreground)),
        ],
      ),
    );
  }
}

class SaleDetailThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  const SaleDetailThumbnail({super.key, required this.imageUrl, required this.localImagePath});
  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, width: 64, height: 64, fit: BoxFit.cover));
    }
    if (imageUrl == null || imageUrl!.trim().isEmpty) return Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 32));
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl!, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400))));
  }
}

class TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const TicketRow({super.key, required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = highlight ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: style)), const SizedBox(width: 16), Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(value, textAlign: TextAlign.right, style: style)))]),
    );
  }
}