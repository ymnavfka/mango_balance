import '../entities/recurring_payment.dart';

abstract class RecurringRepository {
  Stream<List<RecurringPaymentEntity>> watchRecurringPayments(int profileId);

  /// Активные платежи профиля — нужны планировщику для материализации
  /// наступивших дат в реальные транзакции.
  Future<List<RecurringPaymentEntity>> activePayments(int profileId);

  Future<void> addRecurringPayment(RecurringPaymentEntity payment);

  Future<void> updateRecurringPayment(RecurringPaymentEntity payment);

  Future<void> deleteRecurringPayment(int id);

  /// Включение/выключение. При включении пропускает даты, выпавшие на период
  /// отключения (без задним числом).
  Future<void> setActive(int id, bool active);

  Future<void> setNextRunDate(int id, DateTime nextRunDate);
}
