import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../bloc/customer_bloc.dart';

import '../widgets/customer_widgets.dart'; // Importamos los widgets visuales refactorizados

class _LedgerGroup {
  final String title;
  final List<CustomerLedgerEntry> entries;
  final DateTime sortDate;

  _LedgerGroup({
    required this.title,
    required this.entries,
    required this.sortDate,
  });
}

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());
    context.read<CustomerBloc>().add(LoadCustomerDetailData(widget.customer.id));
  }

  // --- MÉTODOS DE LÓGICA Y FORMATEO (MANTENIDOS INTACTOS) ---
  String _formatCurrency(double value) => '\$${value.toStringAsFixed(2)} MXN';

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  String _formatShortDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _entryTypeLabel(String type) {
    switch (type) {
      case 'manual_charge': return 'Cargo manual';
      case 'product_charge': return 'Cargo por productos';
      case 'payment': return 'Abono';
      case 'settlement': return 'Liquidación';
      default: return type;
    }
  }

  Color _entryTypeColor(String type) {
    switch (type) {
      case 'manual_charge':
      case 'product_charge': return Colors.orange;
      case 'payment': return Colors.blue;
      case 'settlement': return Colors.green;
      default: return Colors.grey;
    }
  }

  bool _isChargeType(String type) => type == 'manual_charge' || type == 'product_charge';

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash': return 'Efectivo';
      case 'transfer': return 'Transferencia';
      case 'point': return 'Tarjeta / Point';
      default: return method;
    }
  }

  String _buildItemsSummary(CustomerLedgerEntry entry) {
    if (entry.items.isEmpty) return '';
    final names = entry.items.map((item) => item.productName).toList();
    final visible = names.take(3).join(', ');
    final remaining = names.length - 3;
    if (remaining > 0) return '$visible +$remaining más';
    return visible;
  }

  String _buildLedgerDayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    const months = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${date.day} de ${months[date.month]} de ${date.year}';
  }

  List<_LedgerGroup> _groupLedgerEntries(List<CustomerLedgerEntry> entries) {
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final Map<String, List<CustomerLedgerEntry>> grouped = {};

    for (final entry in sorted) {
      final date = entry.createdAt;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped.entries.map((group) {
      final first = group.value.first;
      return _LedgerGroup(
        title: _buildLedgerDayTitle(first.createdAt),
        entries: group.value,
        sortDate: DateTime(first.createdAt.year, first.createdAt.month, first.createdAt.day),
      );
    }).toList()..sort((a, b) => b.sortDate.compareTo(a.sortDate));
  }

  List<CustomerLedgerEntry> _entriesForCycle(List<CustomerLedgerEntry> entries, String cycleId) {
    return entries.where((entry) => entry.debtCycleId == cycleId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int _totalItemsForCycle(List<CustomerLedgerEntry> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.items.fold<int>(0, (itemsSum, item) => itemsSum + item.quantity));
  }

  Future<void> _openManualCharge(Customer customer) async {
    final result = await context.push<bool>('/customers/manual-charge', extra: customer);
    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(LoadCustomerDetailData(customer.id));
    }
  }

  Future<void> _openPayment(Customer customer) async {
    final result = await context.push<bool>('/customers/payment', extra: customer);
    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(LoadCustomerDetailData(customer.id));
    }
  }

  // --- CONSTRUCCIÓN DE LA VISTA PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CustomerBloc, CustomerState>(
      listenWhen: (previous, current) => previous.message != current.message && current.status == CustomerStatus.error,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final currentCustomer = state.customers.cast<Customer?>().firstWhere(
              (customer) => customer?.id == widget.customer.id,
              orElse: () => widget.customer,
            )!;

        final hasDebt = currentCustomer.currentBalance > 0;
        final ledgerEntries = state.ledgerEntries;
        final openDebtCycle = state.openDebtCycle;
        final closedDebtCycles = state.closedDebtCycles;

        final openEntries = openDebtCycle == null ? <CustomerLedgerEntry>[] : _entriesForCycle(ledgerEntries, openDebtCycle.id);
        final isInitialLoading = state.status == CustomerStatus.loading && ledgerEntries.isEmpty && openDebtCycle == null && closedDebtCycles.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del cliente'),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.chevron_left, size: 32, color: theme.primaryColor),
              onPressed: () => context.pop(),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<CustomerBloc>().add(const LoadCustomers());
              context.read<CustomerBloc>().add(LoadCustomerDetailData(currentCustomer.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                // --- PERFIL DEL CLIENTE ---
                Container(
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
                      Text(currentCustomer.name, style: theme.textTheme.displayMedium?.copyWith(fontSize: 26, color: Colors.black87)),
                      if (currentCustomer.phone != null && currentCustomer.phone!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(currentCustomer.phone!, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700])),
                      ],
                      if (currentCustomer.notes != null && currentCustomer.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('Nota: ${currentCustomer.notes!}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber.shade900, fontWeight: FontWeight.bold, height: 1.4)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12, runSpacing: 12,
                        children: [
                          CustomerInfoCard(label: 'Saldo actual', value: _formatCurrency(currentCustomer.currentBalance), highlight: hasDebt),
                          CustomerInfoCard(label: 'Estado', value: hasDebt ? 'Con pendiente' : 'Sin adeudo'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (isInitialLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  
                  // --- SECCIÓN: ADEUDO ACTUAL ---
                  Text('Adeudo en Curso', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  
                  if (openDebtCycle != null) ...[
                    DebtCycleSummaryCard(
                      title: 'Adeudo activo',
                      subtitle: 'Iniciado el ${_formatShortDate(openDebtCycle.openedAt)}',
                      statusText: 'Activo',
                      statusColor: const Color(0xFFDC2626),
                      totalChargedText: _formatCurrency(openDebtCycle.totalCharged),
                      totalPaidText: _formatCurrency(openDebtCycle.totalPaid),
                      finalBalanceText: _formatCurrency(openDebtCycle.finalBalance),
                      movementCountText: '${openDebtCycle.movementCount} movimiento${openDebtCycle.movementCount == 1 ? '' : 's'}',
                      totalItemsText: '${_totalItemsForCycle(openEntries)} artículo${_totalItemsForCycle(openEntries) == 1 ? '' : 's'}',
                    ),
                    const SizedBox(height: 24),
                    
                    Text('Movimientos del adeudo', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    
                    if (openEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E5EA))),
                        child: Text('Este adeudo todavía no muestra movimientos visibles.', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.4)),
                      )
                    else
                      ..._groupLedgerEntries(openEntries).expand((group) => [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Text(group.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.grey[800], letterSpacing: 0.2)),
                        ),
                        ...group.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomerLedgerCard(
                            entry: entry,
                            typeLabel: _entryTypeLabel(entry.type),
                            typeColor: _entryTypeColor(entry.type),
                            amountText: '${_isChargeType(entry.type) ? '+' : '-'} ${_formatCurrency(entry.amount)}',
                            balanceText: _formatCurrency(entry.balanceAfter),
                            dateText: _formatDate(entry.createdAt),
                            paymentMethodLabel: _paymentMethodLabel,
                            formatCurrency: _formatCurrency,
                            itemsSummary: _buildItemsSummary(entry),
                          ),
                        )),
                      ]),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E5EA))),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book_outlined, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No hay adeudo activo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Cuando este cliente tenga compras a crédito o cargos pendientes, aparecerán aquí.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600], height: 1.4)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  // --- SECCIÓN: HISTORIAL DE LIQUIDADOS ---
                  Text('Adeudos liquidados', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  
                  if (closedDebtCycles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E5EA))),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aún no hay adeudos liquidados', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('Cuando cierres un adeudo completo, se guardará aquí como historial de pagos terminados.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600], height: 1.4)),
                        ],
                      ),
                    )
                  else
                    ...closedDebtCycles.map((cycle) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClosedDebtCycleCard(
                        cycle: cycle,
                        entries: _entriesForCycle(ledgerEntries, cycle.id),
                        formatCurrency: _formatCurrency,
                        formatDate: _formatDate,
                        formatShortDate: _formatShortDate,
                        entryTypeLabel: _entryTypeLabel,
                        entryTypeColor: _entryTypeColor,
                        isChargeType: _isChargeType,
                        paymentMethodLabel: _paymentMethodLabel,
                        buildItemsSummary: _buildItemsSummary,
                        groupLedgerEntries: (entries) => _groupLedgerEntries(entries), // Pasamos la función local
                        totalItemsText: '${_totalItemsForCycle(_entriesForCycle(ledgerEntries, cycle.id))} artículo${_totalItemsForCycle(_entriesForCycle(ledgerEntries, cycle.id)) == 1 ? '' : 's'}',
                      ),
                    )),
                ],

                const SizedBox(height: 32),
                
                // --- BOTONES DE ACCIÓN (Extra grandes y accesibles) ---
                FilledButton.icon(
                  onPressed: () => _openManualCharge(currentCustomer),
                  icon: const Icon(Icons.playlist_add, size: 28),
                  label: const Text('Agregar Cargo Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: hasDebt ? () => _openPayment(currentCustomer) : null,
                  icon: const Icon(Icons.payments_outlined, size: 28),
                  label: const Text('Registrar Abono', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: hasDebt ? theme.primaryColor : Colors.grey.shade300, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}