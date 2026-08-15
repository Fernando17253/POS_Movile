import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/customer.dart';
import '../entities/customer_debt_cycle.dart';
import '../entities/customer_ledger_entry.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers();
  Future<Either<Failure, void>> addCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);

  Future<Either<Failure, List<CustomerLedgerEntry>>> getCustomerLedger(
    String customerId,
  );

  Future<Either<Failure, void>> addCustomerLedgerEntry(
    CustomerLedgerEntry entry,
  );

  Future<Either<Failure, CustomerDebtCycle?>> getOpenDebtCycle(
    String customerId,
  );

  Future<Either<Failure, List<CustomerDebtCycle>>> getClosedDebtCycles(
    String customerId,
  );

  Future<Either<Failure, List<CustomerDebtCycle>>> getAllClosedDebtCycles();

  Future<Either<Failure, void>> saveDebtCycle(
    CustomerDebtCycle cycle,
  );

  Future<Either<Failure, List<CustomerLedgerEntry>>> getDebtCycleEntries(
    String debtCycleId,
  );
}