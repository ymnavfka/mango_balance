import '../repositories/budget_repository.dart';

class DeleteBudget {
  DeleteBudget(this.repository);

  final BudgetRepository repository;

  Future<void> call(int id) {
    return repository.deleteBudget(id);
  }
}
