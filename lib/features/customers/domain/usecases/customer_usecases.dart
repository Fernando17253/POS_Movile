import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../entities/customer_debt_cycle.dart';
import '../entities/customer_ledger_entry.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase implements UseCase<List<Customer>, NoParams> {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(NoParams params) {
    return repository.getCustomers();
  }
}

class AddCustomerUseCase implements UseCase<void, Customer> {
  final CustomerRepository repository;

  AddCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Customer params) {
    return repository.addCustomer(params);
  }
}

class UpdateCustomerUseCase implements UseCase<void, Customer> {
  final CustomerRepository repository;

  UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Customer params) {
    return repository.updateCustomer(params);
  }
}

class DeleteCustomerUseCase implements UseCase<void, String> {
  final CustomerRepository repository;

  DeleteCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteCustomer(params);
  }
}

class GetCustomerLedgerUseCase
    implements UseCase<List<CustomerLedgerEntry>, String> {
  final CustomerRepository repository;

  GetCustomerLedgerUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerLedgerEntry>>> call(String params) {
    return repository.getCustomerLedger(params);
  }
}

class AddCustomerLedgerEntryUseCase
    implements UseCase<void, CustomerLedgerEntry> {
  final CustomerRepository repository;

  AddCustomerLedgerEntryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CustomerLedgerEntry params) {
    return repository.addCustomerLedgerEntry(params);
  }
}

class GetOpenDebtCycleUseCase
    implements UseCase<CustomerDebtCycle?, String> {
  final CustomerRepository repository;

  GetOpenDebtCycleUseCase(this.repository);

  @override
  Future<Either<Failure, CustomerDebtCycle?>> call(String params) {
    return repository.getOpenDebtCycle(params);
  }
}

class GetClosedDebtCyclesUseCase
    implements UseCase<List<CustomerDebtCycle>, String> {
  final CustomerRepository repository;

  GetClosedDebtCyclesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerDebtCycle>>> call(String params) {
    return repository.getClosedDebtCycles(params);
  }
}

class SaveDebtCycleUseCase implements UseCase<void, CustomerDebtCycle> {
  final CustomerRepository repository;

  SaveDebtCycleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CustomerDebtCycle params) {
    return repository.saveDebtCycle(params);
  }
}

class GetAllClosedDebtCyclesUseCase
    implements UseCase<List<CustomerDebtCycle>, NoParams> {
  final CustomerRepository repository;

  GetAllClosedDebtCyclesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerDebtCycle>>> call(NoParams params) {
    return repository.getAllClosedDebtCycles();
  }
}

class GetDebtCycleEntriesUseCase
    implements UseCase<List<CustomerLedgerEntry>, String> {
  final CustomerRepository repository;

  GetDebtCycleEntriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerLedgerEntry>>> call(String params) {
    return repository.getDebtCycleEntries(params);
  }
}