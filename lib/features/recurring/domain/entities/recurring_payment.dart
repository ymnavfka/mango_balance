import '../../../../core/enums/transaction_type.dart';
import 'recurring_interval.dart';

/// Регулярный платёж — шаблон, по которому при наступлении даты автоматически
/// создаётся обычная транзакция. Поддерживаются только пополнения и списания
/// ([TransactionType.income] / [TransactionType.expense]).
class RecurringPaymentEntity {
  const RecurringPaymentEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    required this.intervalUnit,
    required this.intervalCount,
    required this.startDate,
    required this.nextRunDate,
    required this.isActive,
  });

  final int id;
  final String name;
  final TransactionType type;
  final double amount;
  final int categoryId;
  final String categoryName;
  final int accountId;
  final String accountName;
  final RecurringInterval intervalUnit;
  final int intervalCount;

  /// Дата первого платежа (выбирается пользователем при создании).
  final DateTime startDate;

  /// Ближайшая дата, на которую ещё не создана транзакция.
  final DateTime nextRunDate;
  final bool isActive;

  RecurringPaymentEntity copyWith({
    int? id,
    String? name,
    TransactionType? type,
    double? amount,
    int? categoryId,
    String? categoryName,
    int? accountId,
    String? accountName,
    RecurringInterval? intervalUnit,
    int? intervalCount,
    DateTime? startDate,
    DateTime? nextRunDate,
    bool? isActive,
  }) {
    return RecurringPaymentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      intervalCount: intervalCount ?? this.intervalCount,
      startDate: startDate ?? this.startDate,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
