import '../../../../core/enums/transaction_type.dart';

class TransactionEntity {
  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
  });
  final int id;
  final TransactionType type;
  final double amount;
  final DateTime date;

  TransactionEntity copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
