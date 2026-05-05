import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/customer.dart';
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
    context.read<CustomerBloc>().add(LoadCustomerLedger(widget.customer.id));
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
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

  Future<void> _openManualCharge(Customer customer) async {
    final result = await context.push<bool>(
      '/customers/manual-charge',
      extra: customer,
    );

    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(LoadCustomerLedger(customer.id));
    }
  }

  Future<void> _openPayment(Customer customer) async {
    final result = await context.push<bool>(
      '/customers/payment',
      extra: customer,
    );

    if (result == true && mounted) {
      context.read<CustomerBloc>().add(const LoadCustomers());
      context.read<CustomerBloc>().add(LoadCustomerLedger(customer.id));
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del cliente'),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<CustomerBloc>().add(const LoadCustomers());
              context.read<CustomerBloc>().add(
                    LoadCustomerLedger(currentCustomer.id),
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Movimientos',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (state.status == CustomerStatus.loading &&
                        ledgerEntries.isEmpty)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ledgerEntries.isEmpty)
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
                          Icons.history_toggle_off,
                          size: 46,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Todavía no hay movimientos',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aquí aparecerán cargos, abonos y liquidaciones del cliente.',
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
                  ...ledgerEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CustomerLedgerCard(
                        entry: entry,
                        typeLabel: _entryTypeLabel(entry.type),
                        typeColor: _entryTypeColor(entry.type),
                        amountText:
                            '${_isChargeType(entry.type) ? '+' : '-'} ${_formatCurrency(entry.amount)}',
                        balanceText: _formatCurrency(entry.balanceAfter),
                        dateText: _formatDate(entry.createdAt),
                        paymentMethodLabel: _paymentMethodLabel,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openManualCharge(currentCustomer),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Agregar cargo manual'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openPayment(currentCustomer),
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

class _CustomerLedgerCard extends StatelessWidget {
  final CustomerLedgerEntry entry;
  final String typeLabel;
  final Color typeColor;
  final String amountText;
  final String balanceText;
  final String dateText;
  final String Function(String) paymentMethodLabel;

  const _CustomerLedgerCard({
    required this.entry,
    required this.typeLabel,
    required this.typeColor,
    required this.amountText,
    required this.balanceText,
    required this.dateText,
    required this.paymentMethodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasPaymentInfo = entry.paymentSplits.isNotEmpty;
    final paymentSummary = entry.paymentSplits
        .map((split) => paymentMethodLabel(split.method))
        .join(', ');

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
          if (entry.description != null && entry.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.description!,
              style: const TextStyle(
                fontSize: 14,
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
                highlight: false,
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
            Text(
              entry.items.map((item) => item.productName).join(', '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (hasPaymentInfo) ...[
            const SizedBox(height: 12),
            Text(
              'Pago: $paymentSummary',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            ...entry.paymentSplits
                .where((split) =>
                    split.reference != null && split.reference!.trim().isNotEmpty)
                .map(
                  (split) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Referencia: ${split.reference!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
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

  const _InfoCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        highlight ? const Color(0xFFFFF1F2) : Colors.grey.shade100;
    final foreground =
        highlight ? const Color(0xFFDC2626) : Colors.grey.shade800;

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