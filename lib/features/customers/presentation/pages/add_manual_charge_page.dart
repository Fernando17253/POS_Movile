import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../bloc/customer_bloc.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';

class AddManualChargePage extends StatefulWidget {
  final Customer customer;

  const AddManualChargePage({
    super.key,
    required this.customer,
  });

  @override
  State<AddManualChargePage> createState() => _AddManualChargePageState();
}

class _AddManualChargePageState extends State<AddManualChargePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final _customerRepository = CustomerRepositoryImpl();

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _currentAmountValue() {
    return _parseDouble(_amountController.text);
  }

  double _balanceAfterPreview() {
    final amount = _currentAmountValue();
    return widget.customer.currentBalance + amount;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el monto';
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return 'Ingresa un número válido';
    }

    if (parsed <= 0) {
      return 'El monto debe ser mayor a 0';
    }

    return null;
  }

  Future<CustomerDebtCycle?> _getOrCreateOpenDebtCycle() async {
    final openCycleResult =
        await _customerRepository.getOpenDebtCycle(widget.customer.id);

    return await openCycleResult.fold(
      (_) async => null,
      (existingCycle) async {
        if (existingCycle != null) {
          return existingCycle;
        }

        final newCycle = CustomerDebtCycle(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          customerId: widget.customer.id,
          customerNameSnapshot: widget.customer.name,
          openedAt: DateTime.now(),
          closedAt: null,
          isClosed: false,
          totalCharged: 0,
          totalPaid: 0,
          finalBalance: widget.customer.currentBalance,
          totalItems: 0,
          movementCount: 0,
        );

        final saveResult = await _customerRepository.saveDebtCycle(newCycle);

        return saveResult.fold(
          (_) => null,
          (_) => newCycle,
        );
      },
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final amount = _parseDouble(_amountController.text);
    final description = _descriptionController.text.trim();
    final now = DateTime.now();
    final balanceAfter = widget.customer.currentBalance + amount;

    setState(() {
      _isSaving = true;
    });

    final openCycle = await _getOrCreateOpenDebtCycle();

    if (!mounted) return;

    if (openCycle == null) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear o recuperar el ciclo de adeudo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entry = CustomerLedgerEntry(
      id: const Uuid().v4(),
      customerId: widget.customer.id,
      debtCycleId: openCycle.id,
      type: 'manual_charge',
      createdAt: now,
      description: description,
      amount: amount,
      balanceAfter: balanceAfter,
      relatedSaleId: null,
      items: const [],
      paymentSplits: const [],
    );

    final ledgerResult = await _customerRepository.addCustomerLedgerEntry(entry);

    if (!mounted) return;

    await ledgerResult.fold(
      (failure) async {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) async {
        final updatedCycle = openCycle.copyWith(
          customerNameSnapshot: widget.customer.name,
          totalCharged: openCycle.totalCharged + amount,
          finalBalance: balanceAfter,
          movementCount: openCycle.movementCount + 1,
          isClosed: false,
          clearClosedAt: true,
        );

        final cycleResult = await _customerRepository.saveDebtCycle(updatedCycle);

        if (!mounted) return;

        cycleResult.fold(
          (failure) {
            setState(() {
              _isSaving = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El cargo se guardó, pero no se pudo actualizar el ciclo: ${failure.message}',
                ),
                backgroundColor: Colors.orange,
              ),
            );

            context.read<CustomerBloc>().add(const LoadCustomers());
            context.read<CustomerBloc>().add(
                  LoadCustomerDetailData(widget.customer.id),
                );

            context.pop(true);
          },
          (_) {
            setState(() {
              _isSaving = false;
            });

            context.read<CustomerBloc>().add(const LoadCustomers());
            context.read<CustomerBloc>().add(
                  LoadCustomerDetailData(widget.customer.id),
                );

            context.pop(true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar cargo manual'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomerSummaryCard(
                  title: customer.name,
                  subtitle: customer.phone,
                  balanceText: _formatCurrency(customer.currentBalance),
                  nextBalanceText: _formatCurrency(_balanceAfterPreview()),
                ),
                const SizedBox(height: 20),
                const InputLabel(text: 'Monto del cargo'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: _amountValidator,
                ),
                const SizedBox(height: 20),
                const InputLabel(text: 'Descripción'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una descripción';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText:
                        'Ej. Pendiente de refresco, ajuste manual, préstamo pequeño, etc.',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Este cargo aumentará el saldo pendiente del cliente y se agregará al adeudo activo.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _isSaving ? null : _submit,
        icon: _isSaving ? Icons.hourglass_top : Icons.playlist_add,
        label: _isSaving ? 'Guardando cargo...' : 'Guardar cargo',
        isLoading: _isSaving,
      ),
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String balanceText;
  final String nextBalanceText;

  const _CustomerSummaryCard({
    required this.title,
    required this.subtitle,
    required this.balanceText,
    required this.nextBalanceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryInfoCard(
                label: 'Saldo actual',
                value: balanceText,
              ),
              _SummaryInfoCard(
                label: 'Saldo después',
                value: nextBalanceText,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryInfoCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        highlight ? const Color(0xFFFFF7ED) : Colors.grey.shade100;
    final foreground =
        highlight ? const Color(0xFFEA580C) : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
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