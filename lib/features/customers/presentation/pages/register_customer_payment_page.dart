import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/entities/payment_split.dart';
import '../bloc/customer_bloc.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';

class RegisterCustomerPaymentPage extends StatefulWidget {
  final Customer customer;

  const RegisterCustomerPaymentPage({
    super.key,
    required this.customer,
  });

  @override
  State<RegisterCustomerPaymentPage> createState() =>
      _RegisterCustomerPaymentPageState();
}

class _RegisterCustomerPaymentPageState
    extends State<RegisterCustomerPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  final _customerRepository = CustomerRepositoryImpl();

  String _paymentMethod = 'cash';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
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
    final next = widget.customer.currentBalance - _currentAmountValue();
    return next < 0 ? 0 : next;
  }

  bool _willSettle() {
    if (widget.customer.currentBalance <= 0) return false;
    return _currentAmountValue() >= widget.customer.currentBalance &&
        _currentAmountValue() > 0;
  }

  String _movementPreviewLabel() {
    return _willSettle() ? 'Liquidación' : 'Abono';
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

    if (widget.customer.currentBalance <= 0) {
      return 'Este cliente no tiene saldo pendiente';
    }

    if (parsed > widget.customer.currentBalance) {
      return 'El monto no puede ser mayor al saldo pendiente';
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

        final recoveryCycle = CustomerDebtCycle(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          customerId: widget.customer.id,
          customerNameSnapshot: widget.customer.name,
          openedAt: DateTime.now(),
          closedAt: null,
          isClosed: false,
          totalCharged: widget.customer.currentBalance,
          totalPaid: 0,
          finalBalance: widget.customer.currentBalance,
          totalItems: 0,
          movementCount: 0,
        );

        final saveResult = await _customerRepository.saveDebtCycle(recoveryCycle);

        return saveResult.fold(
          (_) => null,
          (_) => recoveryCycle,
        );
      },
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (widget.customer.currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene adeudo pendiente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = _parseDouble(_amountController.text);
    final reference = _referenceController.text.trim().isEmpty
        ? null
        : _referenceController.text.trim();

    final newBalance = widget.customer.currentBalance - amount;
    final normalizedBalance = newBalance < 0 ? 0.0 : newBalance;
    final isSettlement = normalizedBalance <= 0;
    final now = DateTime.now();

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
      type: isSettlement ? 'settlement' : 'payment',
      createdAt: now,
      description: isSettlement
          ? 'Liquidación de adeudo'
          : 'Abono registrado',
      amount: amount,
      balanceAfter: normalizedBalance,
      relatedSaleId: null,
      items: const [],
      paymentSplits: [
        PaymentSplit(
          method: _paymentMethod,
          amount: amount,
          reference: _paymentMethod == 'transfer' ? reference : null,
        ),
      ],
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
          totalPaid: openCycle.totalPaid + amount,
          finalBalance: normalizedBalance,
          movementCount: openCycle.movementCount + 1,
          isClosed: isSettlement,
          closedAt: isSettlement ? now : null,
          clearClosedAt: !isSettlement,
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
                  'El abono se guardó, pero no se pudo actualizar el ciclo: ${failure.message}',
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
        title: const Text('Registrar abono'),
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
                _CustomerPaymentHeader(
                  customerName: customer.name,
                  balanceText: _formatCurrency(customer.currentBalance),
                  nextBalanceText: _formatCurrency(_balanceAfterPreview()),
                  movementLabel: _movementPreviewLabel(),
                ),
                const SizedBox(height: 20),
                const InputLabel(text: 'Monto a pagar'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: _amountValidator,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 20),
                const InputLabel(text: 'Método de pago'),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  items: const [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(
                      value: 'point',
                      child: Text('Tarjeta / Point'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _paymentMethod = value;
                      if (_paymentMethod != 'transfer') {
                        _referenceController.clear();
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Selecciona método',
                  ),
                ),
                if (_paymentMethod == 'transfer') ...[
                  const SizedBox(height: 20),
                  const InputLabel(text: 'Referencia (opcional)'),
                  TextFormField(
                    controller: _referenceController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Folio o referencia',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _willSettle()
                        ? 'Este movimiento liquidará por completo el adeudo del cliente.'
                        : 'Este movimiento registrará un abono y reducirá el saldo pendiente del cliente.',
                    style: const TextStyle(
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
        icon: _isSaving ? Icons.hourglass_top : Icons.payments_outlined,
        label: _isSaving ? 'Guardando abono...' : 'Guardar abono',
        isLoading: _isSaving,
      ),
    );
  }
}

class _CustomerPaymentHeader extends StatelessWidget {
  final String customerName;
  final String balanceText;
  final String nextBalanceText;
  final String movementLabel;

  const _CustomerPaymentHeader({
    required this.customerName,
    required this.balanceText,
    required this.nextBalanceText,
    required this.movementLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isSettlement = movementLabel == 'Liquidación';

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
            customerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PaymentInfoCard(
                label: 'Saldo pendiente',
                value: balanceText,
                foreground: const Color(0xFFDC2626),
                background: const Color(0xFFFFF1F2),
              ),
              _PaymentInfoCard(
                label: 'Saldo después',
                value: nextBalanceText,
                foreground: isSettlement
                    ? const Color(0xFF15803D)
                    : const Color(0xFF1D4ED8),
                background: isSettlement
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFEFF6FF),
              ),
              _PaymentInfoCard(
                label: 'Movimiento',
                value: movementLabel,
                foreground: isSettlement
                    ? const Color(0xFF15803D)
                    : const Color(0xFF1D4ED8),
                background: isSettlement
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFEFF6FF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color foreground;
  final Color background;

  const _PaymentInfoCard({
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
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