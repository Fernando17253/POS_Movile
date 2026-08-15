part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  const LoadCustomers();
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class AddCustomerEvent extends CustomerEvent {
  final Customer customer;

  const AddCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;

  const DeleteCustomerEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCustomerLedger extends CustomerEvent {
  final String customerId;

  const LoadCustomerLedger(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class AddCustomerLedgerEntryEvent extends CustomerEvent {
  final CustomerLedgerEntry entry;

  const AddCustomerLedgerEntryEvent(this.entry);

  @override
  List<Object?> get props => [entry];
}

class LoadCustomerDetailData extends CustomerEvent {
  final String customerId;

  const LoadCustomerDetailData(this.customerId);

  @override
  List<Object?> get props => [customerId];
}