import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseDouble(_amountController.text);
    final description = _descriptionController.text.trim();
    final balanceAfter = widget.customer.currentBalance + amount;

    final entry = CustomerLedgerEntry(
      id: const Uuid().v4(),
      customerId: widget.customer.id,
      type: 'manual_charge',
      createdAt: DateTime.now(),
      description: description,
      amount: amount,
      balanceAfter: balanceAfter,
      relatedSaleId: null,
      items: const [],
      paymentSplits: const [],
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
                  ),
                  const SizedBox(height: 20),
                  const InputLabel(text: 'Monto del cargo'),
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
                  const InputLabel(text: 'Descripción'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa una descripción';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ej. Pendiente de refresco, ajuste manual, etc.',
                    ),
                  ),
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
              icon: isLoading ? Icons.hourglass_top : Icons.playlist_add,
              label: isLoading ? 'Guardando cargo...' : 'Guardar cargo',
              isLoading: isLoading,
            );
          },
        ),
      ),
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String balanceText;

  const _CustomerSummaryCard({
    required this.title,
    required this.subtitle,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SALDO ACTUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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