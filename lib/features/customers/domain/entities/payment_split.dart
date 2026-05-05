import 'package:equatable/equatable.dart';

class PaymentSplit extends Equatable {
  final String method; // cash | transfer | point
  final double amount;
  final String? reference;

  const PaymentSplit({
    required this.method,
    required this.amount,
    this.reference,
  });

  PaymentSplit copyWith({
    String? method,
    double? amount,
    String? reference,
  }) {
    return PaymentSplit(
      method: method ?? this.method,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
    );
  }

  @override
  List<Object?> get props => [
        method,
        amount,
        reference,
      ];
}