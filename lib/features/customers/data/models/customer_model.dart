import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 20)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phone;

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final double currentBalance;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.isActive,
    required this.currentBalance,
  });

  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      notes: notes,
      createdAt: createdAt,
      isActive: isActive,
      currentBalance: currentBalance,
    );
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      notes: customer.notes,
      createdAt: customer.createdAt,
      isActive: customer.isActive,
      currentBalance: customer.currentBalance,
    );
  }
}