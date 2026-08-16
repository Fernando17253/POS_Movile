import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';

// ==========================================
// WIDGETS DE LA LISTA DE CLIENTES
// ==========================================

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final String balanceText;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.balanceText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDebt = customer.currentBalance > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomerAvatar(name: customer.name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (customer.phone != null && customer.phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(customer.phone!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      CustomerChip(label: hasDebt ? 'Adeudo' : 'Saldo', value: balanceText, highlight: hasDebt),
                      CustomerChip(label: 'Estado', value: hasDebt ? 'Con pendiente' : 'Sin adeudo'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 28), color: AppTheme.primaryColor, tooltip: 'Editar'),
                const SizedBox(height: 8),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 28), color: Colors.red, tooltip: 'Eliminar'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerAvatar extends StatelessWidget {
  final String name;

  const CustomerAvatar({super.key, required this.name});

  String _buildInitials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(_buildInitials(name), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
    );
  }
}

class CustomerChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const CustomerChip({super.key, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight ? const Color(0xFFFFF1F2) : Colors.grey.shade100;
    final foreground = highlight ? const Color(0xFFDC2626) : Colors.grey.shade800;

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground.withValues(alpha: 0.8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: foreground))),
        ],
      ),
    );
  }
}

class EmptyCustomersState extends StatelessWidget {
  final bool hasSearch;

  const EmptyCustomersState({super.key, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasSearch ? Icons.search_off_outlined : Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(hasSearch ? 'No se encontraron clientes' : 'Aún no hay clientes registrados', textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(hasSearch ? 'Prueba buscando con otro nombre o número de teléfono.' : 'Agrega tu primer cliente a la libreta para comenzar a registrar adeudos y abonos.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGETS DEL DETALLE DEL CLIENTE Y LIBRETA
// ==========================================

class CustomerInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? accentColor;

  const CustomerInfoCard({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = accentColor != null ? accentColor!.withValues(alpha: 0.10) : highlight ? const Color(0xFFFFF1F2) : Colors.grey.shade100;
    final foreground = accentColor ?? (highlight ? const Color(0xFFDC2626) : Colors.grey.shade800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: foreground.withValues(alpha: 0.8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: foreground))),
        ],
      ),
    );
  }
}

class DebtCycleSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final String totalChargedText;
  final String totalPaidText;
  final String finalBalanceText;
  final String movementCountText;
  final String totalItemsText;

  const DebtCycleSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.totalChargedText,
    required this.totalPaidText,
    required this.finalBalanceText,
    required this.movementCountText,
    required this.totalItemsText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              CustomerInfoCard(label: 'Total cargado', value: totalChargedText),
              CustomerInfoCard(label: 'Total abonado', value: totalPaidText, accentColor: const Color(0xFF1D4ED8)),
              CustomerInfoCard(label: 'Saldo actual', value: finalBalanceText, highlight: true),
              CustomerInfoCard(label: 'Movimientos', value: movementCountText),
              CustomerInfoCard(label: 'Artículos', value: totalItemsText),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerLedgerCard extends StatelessWidget {
  final CustomerLedgerEntry entry;
  final String typeLabel;
  final Color typeColor;
  final String amountText;
  final String balanceText;
  final String dateText;
  final String Function(String) paymentMethodLabel;
  final String Function(double) formatCurrency;
  final String itemsSummary;

  const CustomerLedgerCard({
    super.key,
    required this.entry,
    required this.typeLabel,
    required this.typeColor,
    required this.amountText,
    required this.balanceText,
    required this.dateText,
    required this.paymentMethodLabel,
    required this.formatCurrency,
    required this.itemsSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPaymentInfo = entry.paymentSplits.isNotEmpty;
    final totalArticles = entry.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                child: Text(typeLabel, style: TextStyle(color: typeColor, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
                child: Text(dateText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          if (entry.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(entry.description, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (entry.type == 'settlement') ...[
            const SizedBox(height: 12),
            Text('El cliente liquidó su adeudo.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              CustomerInfoCard(label: 'Movimiento', value: amountText, accentColor: typeColor),
              CustomerInfoCard(label: 'Saldo después', value: balanceText, highlight: entry.balanceAfter > 0),
            ],
          ),
          if (entry.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            CustomerInfoCard(label: 'Productos', value: '$totalArticles artículo${totalArticles == 1 ? '' : 's'}'),
            const SizedBox(height: 8),
            Text(itemsSummary, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4)),
          ],
          if (hasPaymentInfo) ...[
            const SizedBox(height: 16),
            Text('Métodos de pago', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.grey[800])),
            const SizedBox(height: 8),
            ...entry.paymentSplits.map((split) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${paymentMethodLabel(split.method)}: ${formatCurrency(split.amount)}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                  if (split.reference != null && split.reference!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Referencia: ${split.reference!}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontSize: 13)),
                    ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class ClosedDebtCycleCard extends StatelessWidget {
  final CustomerDebtCycle cycle;
  final List<CustomerLedgerEntry> entries;
  final String Function(double) formatCurrency;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatShortDate;
  final String Function(String) entryTypeLabel;
  final Color Function(String) entryTypeColor;
  final bool Function(String) isChargeType;
  final String Function(String) paymentMethodLabel;
  final String Function(CustomerLedgerEntry) buildItemsSummary;
  final List<dynamic> Function(List<CustomerLedgerEntry>) groupLedgerEntries; // dynamic para evitar ref cruzada circular
  final String totalItemsText;

  const ClosedDebtCycleCard({
    super.key,
    required this.cycle,
    required this.entries,
    required this.formatCurrency,
    required this.formatDate,
    required this.formatShortDate,
    required this.entryTypeLabel,
    required this.entryTypeColor,
    required this.isChargeType,
    required this.paymentMethodLabel,
    required this.buildItemsSummary,
    required this.groupLedgerEntries,
    required this.totalItemsText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodText = '${formatShortDate(cycle.openedAt)} - ${cycle.closedAt != null ? formatShortDate(cycle.closedAt!) : 'Sin cierre'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text('Adeudo liquidado', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Periodo: $periodText', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(999)),
            child: const Text('Liquidado', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          children: [
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                CustomerInfoCard(label: 'Inicio', value: formatShortDate(cycle.openedAt)),
                CustomerInfoCard(label: 'Cierre', value: cycle.closedAt != null ? formatShortDate(cycle.closedAt!) : '—', accentColor: const Color(0xFF15803D)),
                CustomerInfoCard(label: 'Total adeudado', value: formatCurrency(cycle.totalCharged)),
                CustomerInfoCard(label: 'Total abonado', value: formatCurrency(cycle.totalPaid), accentColor: const Color(0xFF1D4ED8)),
                CustomerInfoCard(label: 'Saldo final', value: formatCurrency(cycle.finalBalance), accentColor: const Color(0xFF15803D)),
                CustomerInfoCard(label: 'Movimientos', value: '${cycle.movementCount} movimiento${cycle.movementCount == 1 ? '' : 's'}'),
                CustomerInfoCard(label: 'Artículos', value: totalItemsText),
              ],
            ),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              Text('No hay movimientos visibles para este ciclo.', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]))
            else
              ...groupLedgerEntries(entries).expand(
                (group) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Text(
                      group.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.grey[700], letterSpacing: 0.5),
                    ),
                  ),
                  ...group.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomerLedgerCard(
                        entry: entry,
                        typeLabel: entryTypeLabel(entry.type),
                        typeColor: entryTypeColor(entry.type),
                        amountText: '${isChargeType(entry.type) ? '+' : '-'} ${formatCurrency(entry.amount)}',
                        balanceText: formatCurrency(entry.balanceAfter),
                        dateText: formatDate(entry.createdAt),
                        paymentMethodLabel: paymentMethodLabel,
                        formatCurrency: formatCurrency,
                        itemsSummary: buildItemsSummary(entry),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TARJETA PARA SELECCIONAR CLIENTE
// ==========================================
class SelectableCustomerCard extends StatelessWidget {
  final Customer customer;
  final String balanceText;
  final VoidCallback onTap;

  const SelectableCustomerCard({
    super.key,
    required this.customer,
    required this.balanceText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDebt = customer.currentBalance > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CustomerAvatar(name: customer.name), // Reutilizamos el grande
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (customer.phone != null && customer.phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.phone!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CustomerChip( // Reutilizamos el chip grande
                    label: 'Saldo actual',
                    value: balanceText,
                    highlight: hasDebt,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.check_circle_outline,
              color: theme.primaryColor,
              size: 32, // Ícono claro de selección
            ),
          ],
        ),
      ),
    );
  }
}