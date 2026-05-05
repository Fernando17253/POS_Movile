import 'package:hive/hive.dart';

import '../../domain/entities/payment_split.dart';

part 'payment_split_model.g.dart';

@HiveType(typeId: 22)
class PaymentSplitModel extends HiveObject {
  @HiveField(0)
  final String method;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String? reference;

  PaymentSplitModel({
    required this.method,
    required this.amount,
    this.reference,
  });

  PaymentSplit toEntity() {
    return PaymentSplit(
      method: method,
      amount: amount,
      reference: reference,
    );
  }

  factory PaymentSplitModel.fromEntity(PaymentSplit split) {
    return PaymentSplitModel(
      method: split.method,
      amount: split.amount,
      reference: split.reference,
    );
  }
}