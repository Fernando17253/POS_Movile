part of 'customer_bloc.dart';

enum CustomerStatus {
  initial,
  loading,
  loaded,
  success,
  error,
}

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final List<CustomerLedgerEntry> ledgerEntries;
  final String searchQuery;
  final String? message;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.ledgerEntries = const [],
    this.searchQuery = '',
    this.message,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    List<CustomerLedgerEntry>? ledgerEntries,
    String? searchQuery,
    String? message,
    bool clearMessage = false,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        filteredCustomers,
        ledgerEntries,
        searchQuery,
        message,
      ];
}