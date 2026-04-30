import '../../../../core/enums/transaction_type.dart';
import '../value_objects/amount.dart';
import '../value_objects/transaction_date.dart';

class TransactionEntity {
  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
  });
  final int id;
  final TransactionType type;
  final Amount amount;
  final TransactionDate date;

  TransactionEntity copyWith({
    int? id,
    TransactionType? type,
    Amount? amount,
    TransactionDate? date,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
