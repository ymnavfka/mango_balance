import '../repositories/recurring_repository.dart';

class DeleteRecurringPayment {
  DeleteRecurringPayment(this.repository);

  final RecurringRepository repository;

  Future<void> call(int id) async {
    await repository.deleteRecurringPayment(id);
  }
}
