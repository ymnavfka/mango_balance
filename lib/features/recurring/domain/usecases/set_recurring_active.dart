import '../repositories/recurring_repository.dart';

class SetRecurringActive {
  SetRecurringActive(this.repository);

  final RecurringRepository repository;

  Future<void> call(int id, bool active) async {
    await repository.setActive(id, active);
  }
}
