import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../bloc/customer_bloc.dart';

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
    context.read<CustomerBloc>().add(
          LoadCustomerDetailData(widget.customer.id),
        );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

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
      case 'manual_charge':
        return 'Cargo manual';
      case 'product_charge':
        return 'Cargo por productos';
      case 'payment':
        return 'Abono';
      case 'settlement':
        return 'Liquidación';
      default:
        return type;
    }
  }

  Color _entryTypeColor(String type) {
    switch (type) {
      case 'manual_charge':
      case 'product_charge':
        return Colors.orange;
      case 'payment':
        return Colors.blue;
      case 'settlement':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isChargeType(String type) {
    return type == 'manual_charge' || type == 'product_charge';
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'point':
        return 'Tarjeta / Point';
      default:
        return method;
    }
  }

  String _buildItemsSummary(CustomerLedgerEntry entry) {
    if (entry.items.isEmpty) return '';

    final names = entry.items.map((item) => item.productName).toList();
    final visible = names.take(3).join(', ');
    final remaining = names.length - 3;

    if (remaining > 0) {
      return '$visible +$remaining más';
    }

    return visible;
  }

  String _buildLedgerDayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';

    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month]} de ${date.year}';
  }

  List<_LedgerGroup> _groupLedgerEntries(List<CustomerLedgerEntry> entries) {
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<CustomerLedgerEntry>> grouped = {};

    for (final entry in sorted) {
      final date = entry.createdAt;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped.entries.map((group) {
      final first = group.value.first;
      return _LedgerGroup(
        title: _buildLedgerDayTitle(first.createdAt),
        entries: group.value,
        sortDate: DateTime(
          first.createdAt.year,
          first.createdAt.month,
          first.createdAt.day,
        ),
      );
    }).toList()
      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
  }

  List<CustomerLedgerEntry> _entriesForCycle(
    List<CustomerLedgerEntry> entries,
    String cycleId,
  ) {
    return entries.where((entry) => entry.debtCycleId == cycleId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int _totalItemsForCycle(List<CustomerLedgerEntry> entries) {
    return entries.fold<int>(
      0,
      (sum, entry) =>
          sum +
          entry.items.fold<int>(
            0,
            (itemsSum, item) => itemsSum + item.quantity,
          ),
    );
  }

  Future<void> _openManualCharge(Customer customer) async {
    final result = await context.push<bool>(
      '/customers/manual-charge',
      extra: customer,
    );

    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(
            LoadCustomerDetailData(customer.id),
          );
    }
  }

  Future<void> _openPayment(Customer customer) async {
    final result = await context.push<bool>(
      '/customers/payment',
      extra: customer,
    );

    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(
            LoadCustomerDetailData(customer.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listenWhen: (previous, current) =>
          previous.message != current.message &&
          current.status == CustomerStatus.error,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
            ),
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

        final openEntries = openDebtCycle == null
            ? <CustomerLedgerEntry>[]
            : _entriesForCycle(ledgerEntries, openDebtCycle.id);

        final isInitialLoading = state.status == CustomerStatus.loading &&
            ledgerEntries.isEmpty &&
            openDebtCycle == null &&
            closedDebtCycles.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del cliente'),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<CustomerBloc>().add(const LoadCustomers());
              context.read<CustomerBloc>().add(
                    LoadCustomerDetailData(currentCustomer.id),
                  );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentCustomer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (currentCustomer.phone != null &&
                          currentCustomer.phone!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          currentCustomer.phone!,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (currentCustomer.notes != null &&
                          currentCustomer.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          currentCustomer.notes!,
                          style: TextStyle(
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoCard(
                            label: 'Saldo actual',
                            value: _formatCurrency(currentCustomer.currentBalance),
                            highlight: hasDebt,
                          ),
                          _InfoCard(
                            label: 'Estado',
                            value: hasDebt ? 'Con pendiente' : 'Sin adeudo',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (isInitialLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  const Text(
                    'Adeudo actual',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (openDebtCycle != null) ...[
                    _DebtCycleSummaryCard(
                      title: 'Adeudo activo',
                      subtitle:
                          'Iniciado el ${_formatShortDate(openDebtCycle.openedAt)}',
                      statusText: 'Activo',
                      statusColor: const Color(0xFFDC2626),
                      totalChargedText:
                          _formatCurrency(openDebtCycle.totalCharged),
                      totalPaidText: _formatCurrency(openDebtCycle.totalPaid),
                      finalBalanceText:
                          _formatCurrency(openDebtCycle.finalBalance),
                      movementCountText:
                          '${openDebtCycle.movementCount} movimiento${openDebtCycle.movementCount == 1 ? '' : 's'}',
                      totalItemsText:
                          '${_totalItemsForCycle(openEntries)} artículo${_totalItemsForCycle(openEntries) == 1 ? '' : 's'}',
                    ),
                    const SizedBox(height: 12),
                    if (openEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Text(
                          'Este adeudo todavía no muestra movimientos visibles.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ..._groupLedgerEntries(openEntries).expand(
                        (group) => [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 4),
                            child: Text(
                              group.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[700],
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          ...group.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CustomerLedgerCard(
                                entry: entry,
                                typeLabel: _entryTypeLabel(entry.type),
                                typeColor: _entryTypeColor(entry.type),
                                amountText:
                                    '${_isChargeType(entry.type) ? '+' : '-'} ${_formatCurrency(entry.amount)}',
                                balanceText:
                                    _formatCurrency(entry.balanceAfter),
                                dateText: _formatDate(entry.createdAt),
                                paymentMethodLabel: _paymentMethodLabel,
                                formatCurrency: _formatCurrency,
                                itemsSummary: _buildItemsSummary(entry),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 46,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay adeudo activo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuando este cliente tenga cargos pendientes, aparecerán aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    'Adeudos liquidados',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (closedDebtCycles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 46,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aún no hay adeudos liquidados',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuando cierres un adeudo completo, se guardará aquí como historial.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...closedDebtCycles.map(
                      (cycle) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ClosedDebtCycleCard(
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
                          groupLedgerEntries: _groupLedgerEntries,
                          totalItemsText:
                              '${_totalItemsForCycle(_entriesForCycle(ledgerEntries, cycle.id))} artículo${_totalItemsForCycle(_entriesForCycle(ledgerEntries, cycle.id)) == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openManualCharge(currentCustomer),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Agregar cargo manual'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: hasDebt ? () => _openPayment(currentCustomer) : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Registrar abono'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtCycleSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final String totalChargedText;
  final String totalPaidText;
  final String finalBalanceText;
  final String movementCountText;
  final String totalItemsText;

  const _DebtCycleSummaryCard({
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoCard(label: 'Total cargado', value: totalChargedText),
              _InfoCard(
                label: 'Total abonado',
                value: totalPaidText,
                accentColor: const Color(0xFF1D4ED8),
              ),
              _InfoCard(
                label: 'Saldo actual',
                value: finalBalanceText,
                highlight: true,
              ),
              _InfoCard(label: 'Movimientos', value: movementCountText),
              _InfoCard(label: 'Artículos', value: totalItemsText),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosedDebtCycleCard extends StatelessWidget {
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
  final List<_LedgerGroup> Function(List<CustomerLedgerEntry>) groupLedgerEntries;
  final String totalItemsText;

  const _ClosedDebtCycleCard({
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
    final periodText =
        '${formatShortDate(cycle.openedAt)} - ${cycle.closedAt != null ? formatShortDate(cycle.closedAt!) : 'Sin cierre'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Adeudo liquidado',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Periodo: $periodText',
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Liquidado',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoCard(
                  label: 'Inicio',
                  value: formatShortDate(cycle.openedAt),
                ),
                _InfoCard(
                  label: 'Cierre',
                  value: cycle.closedAt != null
                      ? formatShortDate(cycle.closedAt!)
                      : '—',
                  accentColor: const Color(0xFF15803D),
                ),
                _InfoCard(
                  label: 'Total adeudado',
                  value: formatCurrency(cycle.totalCharged),
                ),
                _InfoCard(
                  label: 'Total abonado',
                  value: formatCurrency(cycle.totalPaid),
                  accentColor: const Color(0xFF1D4ED8),
                ),
                _InfoCard(
                  label: 'Saldo final',
                  value: formatCurrency(cycle.finalBalance),
                  accentColor: const Color(0xFF15803D),
                ),
                _InfoCard(
                  label: 'Movimientos',
                  value:
                      '${cycle.movementCount} movimiento${cycle.movementCount == 1 ? '' : 's'}',
                ),
                _InfoCard(
                  label: 'Artículos',
                  value: totalItemsText,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                'No hay movimientos visibles para este ciclo.',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              )
            else
              ...groupLedgerEntries(entries).expand(
                (group) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[700],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  ...group.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CustomerLedgerCard(
                        entry: entry,
                        typeLabel: entryTypeLabel(entry.type),
                        typeColor: entryTypeColor(entry.type),
                        amountText:
                            '${isChargeType(entry.type) ? '+' : '-'} ${formatCurrency(entry.amount)}',
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

class _CustomerLedgerCard extends StatelessWidget {
  final CustomerLedgerEntry entry;
  final String typeLabel;
  final Color typeColor;
  final String amountText;
  final String balanceText;
  final String dateText;
  final String Function(String) paymentMethodLabel;
  final String Function(double) formatCurrency;
  final String itemsSummary;

  const _CustomerLedgerCard({
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
    final hasPaymentInfo = entry.paymentSplits.isNotEmpty;
    final totalArticles = entry.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dateText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (entry.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (entry.type == 'settlement') ...[
            const SizedBox(height: 12),
            Text(
              'El cliente liquidó su adeudo.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoCard(
                label: 'Movimiento',
                value: amountText,
                accentColor: typeColor,
              ),
              _InfoCard(
                label: 'Saldo después',
                value: balanceText,
                highlight: entry.balanceAfter > 0,
              ),
            ],
          ),
          if (entry.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              label: 'Productos',
              value: '$totalArticles artículo${totalArticles == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            Text(
              itemsSummary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          if (hasPaymentInfo) ...[
            const SizedBox(height: 12),
            Text(
              'Métodos de pago',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...entry.paymentSplits.map(
              (split) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${paymentMethodLabel(split.method)}: ${formatCurrency(split.amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (split.reference != null &&
                        split.reference!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Referencia: ${split.reference!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? accentColor;

  const _InfoCard({
    required this.label,
    required this.value,
    this.highlight = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final background = accentColor != null
        ? accentColor!.withValues(alpha: 0.10)
        : highlight
            ? const Color(0xFFFFF1F2)
            : Colors.grey.shade100;

    final foreground = accentColor ??
        (highlight ? const Color(0xFFDC2626) : Colors.grey.shade800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

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