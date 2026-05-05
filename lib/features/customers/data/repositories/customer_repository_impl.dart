import 'package:fpdart/fpdart.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../models/customer_ledger_entry_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  @override
  Future<Either<Failure, List<Customer>>> getCustomers() async {
    try {
      final box = HiveDatabase.customerBox;

      final customers = box.values
          .map((model) => model.toEntity())
          .where((customer) => customer.isActive)
          .toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

      return Right(customers);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      final box = HiveDatabase.customerBox;
      final model = CustomerModel.fromEntity(customer);

      await box.put(model.id, model);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      final box = HiveDatabase.customerBox;
      final model = CustomerModel.fromEntity(customer);

      await box.put(model.id, model);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      final box = HiveDatabase.customerBox;
      final existing = box.get(id);

      if (existing == null) {
        return const Right(null);
      }

      final updated = CustomerModel(
        id: existing.id,
        name: existing.name,
        phone: existing.phone,
        notes: existing.notes,
        createdAt: existing.createdAt,
        isActive: false,
        currentBalance: existing.currentBalance,
      );

      await box.put(id, updated);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerLedgerEntry>>> getCustomerLedger(
    String customerId,
  ) async {
    try {
      final box = HiveDatabase.customerLedgerBox;

      final entries = box.values
          .map((model) => model.toEntity())
          .where((entry) => entry.customerId == customerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(entries);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomerLedgerEntry(
    CustomerLedgerEntry entry,
  ) async {
    try {
      final customerBox = HiveDatabase.customerBox;
      final ledgerBox = HiveDatabase.customerLedgerBox;

      final existingCustomer = customerBox.get(entry.customerId);

      if (existingCustomer == null) {
        return const Left(CacheFailure('Cliente no encontrado.'));
      }

      final entryModel = CustomerLedgerEntryModel.fromEntity(entry);

      await ledgerBox.put(entryModel.id, entryModel);

      final updatedCustomer = CustomerModel(
        id: existingCustomer.id,
        name: existingCustomer.name,
        phone: existingCustomer.phone,
        notes: existingCustomer.notes,
        createdAt: existingCustomer.createdAt,
        isActive: existingCustomer.isActive,
        currentBalance: entry.balanceAfter,
      );

      await customerBox.put(updatedCustomer.id, updatedCustomer);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}