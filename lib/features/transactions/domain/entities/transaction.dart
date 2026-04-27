import '../../../../core/enums/transaction_type.dart';

class TransactionEntity {
  final int id; // 👈 добавили
  final TransactionType type;
  final double amount;
  final DateTime date;

  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
  });

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