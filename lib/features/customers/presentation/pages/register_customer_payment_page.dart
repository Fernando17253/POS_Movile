import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
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

  String _paymentMethod = 'cash';

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

  void _submit() {
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
    final isSettlement = newBalance <= 0;

    final entry = CustomerLedgerEntry(
      id: const Uuid().v4(),
      customerId: widget.customer.id,
      type: isSettlement ? 'settlement' : 'payment',
      createdAt: DateTime.now(),
      description: isSettlement
          ? 'Liquidación de adeudo'
          : 'Abono registrado',
      amount: amount,
      balanceAfter: newBalance < 0 ? 0 : newBalance,
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

    context.read<CustomerBloc>().add(
          AddCustomerLedgerEntryEvent(entry),
        );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return BlocListener<CustomerBloc, CustomerState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == CustomerStatus.success &&
            state.message == 'Movimiento guardado correctamente.') {
          context.pop(true);
        }

        if (state.status == CustomerStatus.error && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
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
                  ),
                  const SizedBox(height: 20),
                  const InputLabel(text: 'Monto a pagar'),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                      decoration: const InputDecoration(
                        hintText: 'Ej. Folio o referencia',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            final isLoading = state.status == CustomerStatus.loading;

            return PrimaryButton(
              onPressed: isLoading ? null : _submit,
              icon: isLoading ? Icons.hourglass_top : Icons.payments_outlined,
              label: isLoading ? 'Guardando abono...' : 'Guardar abono',
              isLoading: isLoading,
            );
          },
        ),
      ),
    );
  }
}

class _CustomerPaymentHeader extends StatelessWidget {
  final String customerName;
  final String balanceText;

  const _CustomerPaymentHeader({
    required this.customerName,
    required this.balanceText,
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
            customerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO PENDIENTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}