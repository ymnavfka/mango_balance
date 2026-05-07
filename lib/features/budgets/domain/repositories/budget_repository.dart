import '../entities/budget.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchBudgets(int profileId);
  Future<int> addBudget(BudgetEntity budget);
  Future<void> updateBudget(BudgetEntity budget);
  Future<void> deleteBudget(int id);
}
