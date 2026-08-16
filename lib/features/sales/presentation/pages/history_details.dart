import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sale.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../customers/domain/entities/customer_debt_cycle.dart';
import '../../../customers/domain/entities/customer_ledger_entry.dart';
import '../widgets/history_widgets.dart'; 

String ledgerTypeLabel(Sale sale) => !sale.isCustomerLedger ? '' : sale.isPartialCustomerLedger ? 'Venta con pago parcial' : 'Venta enviada a libreta';
bool isChargeType(String type) => type == 'manual_charge' || type == 'product_charge';

// ==========================================
// 1. PÁGINA DE DETALLE DE VENTA NORMAL
// ==========================================
class SaleDetailPage extends StatelessWidget {
  final Sale sale;
  const SaleDetailPage({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Venta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(buildSaleFolio(sale), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    HistoryInfoChip(label: 'Artículos', value: '$totalItems'),
                    HistoryInfoChip(label: 'Total', value: formatCurrency(sale.total), highlight: true),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Fecha: ${formatDate(sale.createdAt)}', style: theme.textTheme.bodyLarge),
                if (sale.customerName?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Text('Cliente: ${sale.customerName!}', style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 6),
                Text('Método: ${paymentMethodLabel(sale.paymentMethod)}', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleTicketPreviewPage(sale: sale))),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver Ticket', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Productos Adquiridos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...sale.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SaleDetailThumbnail(imageUrl: item.imageUrl, localImagePath: item.localImagePath),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          HistoryInfoChip(label: 'Cant.', value: '${item.quantity}'),
                          HistoryInfoChip(label: 'Precio', value: formatCurrency(item.unitPrice)),
                          HistoryInfoChip(label: 'Subtotal', value: formatCurrency(item.total), highlight: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 2. PÁGINA DE DETALLE DE ADEUDO (LIBRETA)
// ==========================================
class DebtCycleHistoryDetailPage extends StatelessWidget {
  final CustomerDebtCycle cycle;
  final List<CustomerLedgerEntry> entries;

  const DebtCycleHistoryDetailPage({super.key, required this.cycle, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = entries.fold<int>(0, (sum, entry) => sum + entry.items.fold<int>(0, (iSum, item) => iSum + item.quantity));
    final sortedEntries = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Adeudo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cycle.customerNameSnapshot, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    HistoryInfoChip(label: 'Inicio', value: formatDate(cycle.openedAt)),
                    HistoryInfoChip(label: 'Cierre', value: formatDate(cycle.closedAt ?? cycle.openedAt)),
                    HistoryInfoChip(label: 'Adeudado', value: formatCurrency(cycle.totalCharged), highlight: true),
                    HistoryInfoChip(label: 'Abonado', value: formatCurrency(cycle.totalPaid)),
                    HistoryInfoChip(label: 'Saldo final', value: formatCurrency(cycle.finalBalance)),
                    HistoryInfoChip(label: 'Artículos', value: '$totalItems'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Movimientos del adeudo', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...sortedEntries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: paymentMethodColor(entry.type == 'payment' || entry.type == 'settlement' ? 'transfer' : 'customer_ledger').withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ledgerEntryTypeLabel(entry.type),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: entry.type == 'payment' || entry.type == 'settlement' ? Colors.blue : Colors.orange),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
                      child: Text(formatDate(entry.createdAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                if (entry.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(entry.description, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    HistoryInfoChip(label: 'Movimiento', value: '${isChargeType(entry.type) ? '+' : '-'} ${formatCurrency(entry.amount)}', highlight: isChargeType(entry.type)),
                    HistoryInfoChip(label: 'Saldo después', value: formatCurrency(entry.balanceAfter)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 3. PÁGINA DE TICKET (Preparado para Imprimir)
// ==========================================
class SaleTicketPreviewPage extends StatelessWidget {
  final Sale sale;

  const SaleTicketPreviewPage({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(title: const Text('Vista de Ticket')),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, shopState) {
          String shopName = 'Mi tienda';
          String address1 = ''; String phone = ''; String footer = '';

          if (shopState is ShopLoaded) {
            shopName = shopState.shop.name; address1 = shopState.shop.addressLine1;
            phone = shopState.shop.phoneNumber; footer = shopState.shop.footerText;
          }

          return Container(
            color: Colors.grey.shade200,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(shopName, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (address1.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(address1, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                        if (phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Tel. $phone', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black)),
                        
                        TicketRow(label: 'Folio', value: buildSaleFolio(sale)),
                        TicketRow(label: 'Fecha', value: formatDate(sale.createdAt)),
                        TicketRow(label: 'Pago', value: paymentMethodLabel(sale.paymentMethod)),
                        if (sale.amountReceived != null) TicketRow(label: 'Recibido', value: formatCurrency(sale.amountReceived!)),
                        if (sale.changeAmount != null) TicketRow(label: 'Cambio', value: formatCurrency(sale.changeAmount!)),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black)),
                        
                        Align(alignment: Alignment.centerLeft, child: Text('PRODUCTOS', style: theme.textTheme.titleMedium)),
                        const SizedBox(height: 12),
                        ...sale.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.quantity} x ${formatCurrency(item.unitPrice)}', style: theme.textTheme.bodyMedium),
                                  Text(formatCurrency(item.total), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        )),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black)),
                        
                        TicketRow(label: 'Artículos', value: '$totalItems'),
                        const SizedBox(height: 8),
                        TicketRow(label: 'TOTAL', value: formatCurrency(sale.total), highlight: true),
                        
                        if (footer.isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Colors.black)),
                          Text(footer, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                        ],
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