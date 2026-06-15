import '../entities/recurring_payment.dart';
import '../repositories/recurring_repository.dart';

class UpdateRecurringPayment {
  UpdateRecurringPayment(this.repository);

  final RecurringRepository repository;

  Future<void> call(RecurringPaymentEntity payment) async {
    if (payment.name.trim().isEmpty) {
      throw Exception('Название не должно быть пустым');
    }
    if (payment.amount <= 0) {
      throw Exception('Сумма должна быть больше нуля');
    }
    if (payment.intervalCount < 1) {
      throw Exception('Период повторения должен быть не меньше единицы');
    }
    await repository.updateRecurringPayment(payment);
  }
}
