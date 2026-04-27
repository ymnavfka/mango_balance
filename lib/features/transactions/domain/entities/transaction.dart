import '../../../../core/enums/transaction_type.dart';

class TransactionEntity {
  final TransactionType type;
  final double amount;
  final DateTime date;

  TransactionEntity({
    required this.type,
    required this.amount,
    required this.date,
  });
}