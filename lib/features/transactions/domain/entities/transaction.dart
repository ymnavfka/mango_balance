import '../../../../core/enums/transaction_type.dart';
import '../value_objects/amount.dart';
import '../value_objects/transaction_date.dart';

class TransactionEntity {
  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    required this.toAccountId,
    required this.toAccountName,
  });

  final int id;
  final TransactionType type;
  final Amount amount;
  final TransactionDate date;
  final int categoryId;
  final String categoryName;
  final int accountId;
  final String accountName;
  final int? toAccountId;
  final String? toAccountName;

  TransactionEntity copyWith({
    int? id,
    TransactionType? type,
    Amount? amount,
    TransactionDate? date,
    int? categoryId,
    String? categoryName,
    int? accountId,
    String? accountName,
    int? toAccountId,
    String? toAccountName,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      toAccountId: toAccountId ?? this.toAccountId,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }
}
