import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/usecases/add_transaction.dart';
import '../../../transactions/domain/value_objects/amount.dart';
import '../../../transactions/domain/value_objects/transaction_date.dart';
import '../entities/recurring_interval.dart';
import '../entities/recurring_payment.dart';
import '../repositories/recurring_repository.dart';

/// Планировщик регулярных платежей. Приложение офлайн, фонового сервиса нет,
/// поэтому материализация наступивших платежей в реальные транзакции
/// происходит при запуске приложения / смене профиля / правках платежа.
///
/// Для каждого активного платежа создаются транзакции за все пропущенные даты
/// (своя дата у каждой) вплоть до сегодняшнего дня, после чего сдвигается
/// `nextRunDate`.
class RunDueRecurringPayments {
  RunDueRecurringPayments(this.repository, this.addTransaction);

  final RecurringRepository repository;
  final AddTransaction addTransaction;

  /// Предохранитель от бесконечного цикла на испорченных данных.
  static const int _maxOccurrencesPerPayment = 2000;

  Future<void> call(int profileId, {DateTime? now}) async {
    final current = now ?? DateTime.now();
    final tomorrowStart = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(const Duration(days: 1));

    final payments = await repository.activePayments(profileId);
    for (final payment in payments) {
      var next = payment.nextRunDate;
      var generated = 0;
      while (next.isBefore(tomorrowStart) &&
          generated < _maxOccurrencesPerPayment) {
        await addTransaction(_buildTransaction(payment, next));
        next = nextOccurrence(
          next,
          payment.intervalUnit,
          payment.intervalCount,
        );
        generated++;
      }
      if (generated > 0) {
        await repository.setNextRunDate(payment.id, next);
      }
    }
  }

  TransactionEntity _buildTransaction(
    RecurringPaymentEntity payment,
    DateTime date,
  ) {
    return TransactionEntity(
      id: 0,
      type: payment.type,
      amount: Amount(payment.amount),
      date: TransactionDate(date),
      categoryId: payment.categoryId,
      categoryName: payment.categoryName,
      accountId: payment.accountId,
      accountName: payment.accountName,
      toAccountId: payment.accountId,
      toAccountName: payment.accountName,
      comment: payment.name,
    );
  }
}
