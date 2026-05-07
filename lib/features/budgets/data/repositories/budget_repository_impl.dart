import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this.db, this.activeProfile);

  final AppDatabase db;
  final ActiveProfileHolder activeProfile;

  @override
  Stream<List<BudgetEntity>> watchBudgets(int profileId) {
    return db.watchBudgetsByProfile(profileId).map((rows) {
      return rows.map(_mapToEntity).toList();
    });
  }

  @override
  Future<int> addBudget(BudgetEntity budget) async {
    return db.transaction(() async {
      final id = await db.insertBudget(
        BudgetsCompanion.insert(
          profileId: Value(activeProfile.id),
          name: budget.name.trim(),
          limitAmount: budget.limitAmount,
          periodType: budget.period.storageKey,
          allCategories: Value(budget.allCategories),
        ),
      );
      if (!budget.allCategories) {
        for (final categoryId in budget.categoryIds) {
          await db.insertBudgetCategory(id, categoryId);
        }
      }
      return id;
    });
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) async {
    await db.transaction(() async {
      await db.updateBudgetRow(
        Budget(
          id: budget.id,
          profileId: activeProfile.id,
          name: budget.name.trim(),
          limitAmount: budget.limitAmount,
          periodType: budget.period.storageKey,
          allCategories: budget.allCategories,
        ),
      );
      await db.replaceBudgetCategories(
        budget.id,
        budget.allCategories ? const <int>[] : budget.categoryIds,
      );
    });
  }

  @override
  Future<void> deleteBudget(int id) {
    return db.deleteBudget(id);
  }

  BudgetEntity _mapToEntity(BudgetWithCategoryIds row) {
    return BudgetEntity(
      id: row.budget.id,
      name: row.budget.name,
      limitAmount: row.budget.limitAmount,
      period: BudgetPeriodX.fromStorage(row.budget.periodType),
      allCategories: row.budget.allCategories,
      categoryIds: row.categoryIds,
    );
  }
}
