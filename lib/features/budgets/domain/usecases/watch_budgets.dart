import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class WatchBudgets {
  WatchBudgets(this.repository);

  final BudgetRepository repository;

  Stream<List<BudgetEntity>> call(int profileId) {
    return repository.watchBudgets(profileId);
  }
}
