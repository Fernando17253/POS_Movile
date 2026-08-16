import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

import '../widgets/customer_widgets.dart'; // Importamos los nuevos widgets visuales

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());

    _searchController.addListener(() {
      context.read<CustomerBloc>().add(
            SearchCustomers(_searchController.text),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  Future<void> _confirmDelete(Customer customer) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: Text(
            '¿Seguro que deseas eliminar a ${customer.name}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
    }
  }

  void _clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libreta de clientes'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 32, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state.status == CustomerStatus.error && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!), backgroundColor: Colors.red),
            );
          }

          if (state.status == CustomerStatus.success && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          final customers = state.filteredCustomers;

          return Column(
            children: [
              // Buscador Ampliado
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono...',
                    prefixIcon: const Icon(Icons.search, size: 28),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close, size: 28),
                            tooltip: 'Limpiar',
                          ),
                  ),
                ),
              ),
              
              // Lista o Estados Vacíos
              Expanded(
                child: state.status == CustomerStatus.loading && state.customers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : customers.isEmpty
                        ? EmptyCustomersState(
                            hasSearch: state.searchQuery.trim().isNotEmpty,
                          )
                        : ListView.separated(
                            // Agregamos padding inferior de 100 para que el FAB no tape el último cliente
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: customers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final customer = customers[index];

                              return CustomerCard(
                                customer: customer,
                                balanceText: _formatCurrency(customer.currentBalance),
                                onTap: () {
                                  context.push(
                                    '/customers/detail',
                                    extra: customer,
                                  );
                                },
                                onEdit: () {
                                  context.push(
                                    '/customers/upsert',
                                    extra: customer,
                                  );
                                },
                                onDelete: () => _confirmDelete(customer),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/upsert'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1, size: 28),
        label: const Text('Nuevo Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}