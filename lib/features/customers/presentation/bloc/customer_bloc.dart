import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_debt_cycle.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/usecases/customer_usecases.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  final GetCustomerLedgerUseCase getCustomerLedgerUseCase;
  final AddCustomerLedgerEntryUseCase addCustomerLedgerEntryUseCase;
  final GetOpenDebtCycleUseCase getOpenDebtCycleUseCase;
  final GetClosedDebtCyclesUseCase getClosedDebtCyclesUseCase;
  final SaveDebtCycleUseCase saveDebtCycleUseCase;
  final GetDebtCycleEntriesUseCase getDebtCycleEntriesUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
    required this.getCustomerLedgerUseCase,
    required this.addCustomerLedgerEntryUseCase,
    required this.getOpenDebtCycleUseCase,
    required this.getClosedDebtCyclesUseCase,
    required this.saveDebtCycleUseCase,
    required this.getDebtCycleEntriesUseCase,
  }) : super(const CustomerState()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<AddCustomerEvent>(_onAddCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<LoadCustomerLedger>(_onLoadCustomerLedger);
    on<AddCustomerLedgerEntryEvent>(_onAddCustomerLedgerEntry);
    on<LoadCustomerDetailData>(_onLoadCustomerDetailData);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await getCustomersUseCase(NoParams());

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (customers) {
        final filtered = _filterCustomers(customers, state.searchQuery);

        emit(
          state.copyWith(
            status: CustomerStatus.loaded,
            customers: customers,
            filteredCustomers: filtered,
          ),
        );
      },
    );
  }

  void _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) {
    final filtered = _filterCustomers(state.customers, event.query);

    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredCustomers: filtered,
      ),
    );
  }

  Future<void> _onAddCustomer(
    AddCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final duplicatedName = state.customers.any(
      (customer) =>
          customer.name.trim().toLowerCase() ==
          event.customer.name.trim().toLowerCase(),
    );

    if (duplicatedName) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          message: 'Ya existe un cliente con ese nombre.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await addCustomerUseCase(event.customer);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            status: CustomerStatus.success,
            message: 'Cliente guardado correctamente.',
          ),
        );
        add(const LoadCustomers());
      },
    );
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final duplicatedName = state.customers.any(
      (customer) =>
          customer.id != event.customer.id &&
          customer.name.trim().toLowerCase() ==
              event.customer.name.trim().toLowerCase(),
    );

    if (duplicatedName) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          message: 'Ya existe otro cliente con ese nombre.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await updateCustomerUseCase(event.customer);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            status: CustomerStatus.success,
            message: 'Cliente actualizado correctamente.',
          ),
        );
        add(const LoadCustomers());
      },
    );
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await deleteCustomerUseCase(event.id);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            status: CustomerStatus.success,
            message: 'Cliente eliminado correctamente.',
          ),
        );
        add(const LoadCustomers());
      },
    );
  }

  Future<void> _onLoadCustomerLedger(
    LoadCustomerLedger event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await getCustomerLedgerUseCase(event.customerId);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (ledgerEntries) {
        emit(
          state.copyWith(
            status: CustomerStatus.loaded,
            ledgerEntries: ledgerEntries,
          ),
        );
      },
    );
  }

  Future<void> _onLoadCustomerDetailData(
    LoadCustomerDetailData event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final ledgerResult = await getCustomerLedgerUseCase(event.customerId);
    final openCycleResult = await getOpenDebtCycleUseCase(event.customerId);
    final closedCyclesResult = await getClosedDebtCyclesUseCase(event.customerId);

    if (ledgerResult.isLeft()) {
      ledgerResult.fold(
        (failure) => emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        ),
        (_) {},
      );
      return;
    }

    if (openCycleResult.isLeft()) {
      openCycleResult.fold(
        (failure) => emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        ),
        (_) {},
      );
      return;
    }

    if (closedCyclesResult.isLeft()) {
      closedCyclesResult.fold(
        (failure) => emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        ),
        (_) {},
      );
      return;
    }

    final ledgerEntries = ledgerResult.fold<List<CustomerLedgerEntry>>(
      (_) => const [],
      (entries) => entries,
    );

    final openDebtCycle = openCycleResult.fold<CustomerDebtCycle?>(
      (_) => null,
      (cycle) => cycle,
    );

    final closedDebtCycles = closedCyclesResult.fold<List<CustomerDebtCycle>>(
      (_) => const [],
      (cycles) => cycles,
    );

    emit(
      state.copyWith(
        status: CustomerStatus.loaded,
        ledgerEntries: ledgerEntries,
        openDebtCycle: openDebtCycle,
        closedDebtCycles: closedDebtCycles,
        clearOpenDebtCycle: openDebtCycle == null,
      ),
    );
  }

  Future<void> _onAddCustomerLedgerEntry(
    AddCustomerLedgerEntryEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearMessage: true));

    final result = await addCustomerLedgerEntryUseCase(event.entry);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CustomerStatus.error,
            message: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            status: CustomerStatus.success,
            message: 'Movimiento guardado correctamente.',
          ),
        );

        add(const LoadCustomers());
        add(LoadCustomerDetailData(event.entry.customerId));
      },
    );
  }

  List<Customer> _filterCustomers(List<Customer> customers, String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name.toLowerCase().contains(normalized) ||
          (customer.phone?.toLowerCase().contains(normalized) ?? false);
    }).toList();
  }
}