import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/app_validators.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

class UpsertCustomerPage extends StatefulWidget {
  final Customer? customer;

  const UpsertCustomerPage({
    super.key,
    this.customer,
  });

  @override
  State<UpsertCustomerPage> createState() => _UpsertCustomerPageState();
}

class _UpsertCustomerPageState extends State<UpsertCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.customer?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _notesController = TextEditingController(
      text: widget.customer?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      isActive: widget.customer?.isActive ?? true,
      currentBalance: widget.customer?.currentBalance ?? 0,
    );

    if (_isEdit) {
      context.read<CustomerBloc>().add(UpdateCustomerEvent(customer));
    } else {
      context.read<CustomerBloc>().add(AddCustomerEvent(customer));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CustomerBloc, CustomerState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == CustomerStatus.success) {
          context.pop();
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
          title: Text(_isEdit ? 'Editar cliente' : 'Agregar cliente'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 32,
              color: theme.primaryColor,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputLabel(text: 'Nombre'),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.titleMedium,
                    validator: AppValidators.required(
                      'Ingresa el nombre del cliente',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Don José, María, Lupita',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const InputLabel(text: 'Teléfono (opcional)'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: theme.textTheme.titleMedium,
                    decoration: const InputDecoration(
                      hintText: 'Ej. 9611234567',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const InputLabel(text: 'Notas (opcional)'),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Paga cada fin de semana',
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
          child: BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              final isLoading = state.status == CustomerStatus.loading;

              return PrimaryButton(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? Icons.hourglass_top
                    : (_isEdit ? Icons.save : Icons.person_add_alt_1),
                label: isLoading
                    ? 'Guardando...'
                    : (_isEdit ? 'Guardar Cambios' : 'Guardar Cliente'),
                isLoading: isLoading,
              );
            },
          ),
        ),
      ),
    );
  }
}