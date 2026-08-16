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

// Importamos nuestros widgets visuales compartidos
import '../widgets/customer_widgets.dart';

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

  // --- LÓGICA DE NEGOCIO (MANTENIDA INTACTA) ---
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
    if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return 'Ingresa un número válido';
    if (parsed <= 0) return 'El monto debe ser mayor a 0';
    return null;
  }

  Future<CustomerDebtCycle?> _getOrCreateOpenDebtCycle() async {
    final openCycleResult = await _customerRepository.getOpenDebtCycle(widget.customer.id);

    return await openCycleResult.fold(
      (_) async => null,
      (existingCycle) async {
        if (existingCycle != null) return existingCycle;

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

        return saveResult.fold((_) => null, (_) => newCycle);
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

    setState(() => _isSaving = true);

    final openCycle = await _getOrCreateOpenDebtCycle();

    if (!mounted) return;

    if (openCycle == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear o recuperar el ciclo de adeudo.'), backgroundColor: Colors.red),
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
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message), backgroundColor: Colors.red));
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
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('El cargo se guardó, pero falló el ciclo: ${failure.message}'), backgroundColor: Colors.orange));
            context.read<CustomerBloc>().add(const LoadCustomers());
            context.read<CustomerBloc>().add(LoadCustomerDetailData(widget.customer.id));
            context.pop(true);
          },
          (_) {
            setState(() => _isSaving = false);
            context.read<CustomerBloc>().add(const LoadCustomers());
            context.read<CustomerBloc>().add(LoadCustomerDetailData(widget.customer.id));
            context.pop(true);
          },
        );
      },
    );
  }

  // --- INTERFAZ REFACTORIZADA ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar cargo manual'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 32, color: theme.primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de Resumen (Reutilizando widgets)
                Container(
                  width: double.infinity,
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
                      Text(customer.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (customer.phone != null && customer.phone!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(customer.phone!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12, runSpacing: 12,
                        children: [
                          CustomerInfoCard(label: 'Saldo actual', value: _formatCurrency(customer.currentBalance)),
                          CustomerInfoCard(label: 'Saldo después', value: _formatCurrency(_balanceAfterPreview()), accentColor: Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const InputLabel(text: 'Monto del cargo'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  // ¡Texto Gigante para montos de dinero!
                  style: theme.textTheme.displayMedium,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: _amountValidator,
                ),
                
                const SizedBox(height: 24),
                
                const InputLabel(text: 'Descripción'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3, // Reducido ligeramente para no abarcar tanta pantalla
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa una descripción';
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ej. Ajuste manual, préstamo pequeño, etc.',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Mensaje de Advertencia Mejorado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este cargo aumentará el saldo pendiente del cliente y se agregará al adeudo activo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: PrimaryButton(
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving ? Icons.hourglass_top : Icons.playlist_add,
          label: _isSaving ? 'Guardando cargo...' : 'Guardar Cargo',
          isLoading: _isSaving,
        ),
      ),
    );
  }
}