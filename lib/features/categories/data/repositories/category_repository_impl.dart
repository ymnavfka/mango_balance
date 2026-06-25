import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this.db, this.activeProfile);

  final AppDatabase db;
  final ActiveProfileHolder activeProfile;

  @override
  Stream<List<CategoryEntity>> watchCategories(int profileId) {
    return db
        .watchCategoriesByProfile(profileId)
        .map((list) => list.map(_mapToEntity).toList());
  }

  @override
  Future<int> addCategory(CategoryEntity category) async {
    return db.insertCategory(
      CategoriesCompanion.insert(
        name: category.name.trim(),
        type: _mapType(category.type),
        isFallback: Value(category.isFallback),
        profileId: Value(activeProfile.id),
      ),
    );
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    if (category.isFallback) {
      throw Exception('Базовые категории нельзя редактировать');
    }

    final existing = await db.categoryById(category.id);
    if (existing == null) {
      return;
    }

    await db.updateCategory(
      Category(
        id: category.id,
        name: category.name.trim(),
        type: _mapType(category.type),
        isFallback: category.isFallback,
        profileId: existing.profileId,
      ),
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final category = await db.categoryById(id);
    if (category == null) {
      return;
    }

    if (category.isFallback) {
      throw Exception('Базовые категории нельзя удалить');
    }

    final fallback = await db.fallbackCategory(
      category.type,
      category.profileId,
    );
    if (fallback == null) {
      throw Exception('Базовая категория отсутствует');
    }

    await db.replaceCategoryForTransactions(category.id, fallback.id);
    await db.replaceCategoryForRecurringPayments(category.id, fallback.id);
    await db.deleteCategory(id);
  }

  CategoryEntity _mapToEntity(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      type: category.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      isFallback: category.isFallback,
    );
  }

  String _mapType(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }
}
