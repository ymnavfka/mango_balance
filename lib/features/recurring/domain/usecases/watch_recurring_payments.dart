import '../entities/recurring_payment.dart';
import '../repositories/recurring_repository.dart';

class WatchRecurringPayments {
  WatchRecurringPayments(this.repository);

  final RecurringRepository repository;

  Stream<List<RecurringPaymentEntity>> call(int profileId) {
    return repository.watchRecurringPayments(profileId);
  }
}
