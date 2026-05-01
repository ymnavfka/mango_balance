import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return db.watchCategories().map((list) => list.map(_mapToEntity).toList());
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    await db.insertCategory(
      CategoriesCompanion.insert(
        name: category.name.trim(),
        type: _mapType(category.type),
        isFallback: Value(category.isFallback),
      ),
    );
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    if (category.isFallback) {
      throw Exception('Fallback categories cannot be edited');
    }

    await db.updateCategory(
      Category(
        id: category.id,
        name: category.name.trim(),
        type: _mapType(category.type),
        isFallback: category.isFallback,
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
      throw Exception('Fallback categories cannot be deleted');
    }

    final fallback = await db.fallbackCategory(category.type);
    if (fallback == null) {
      throw Exception('Fallback category is missing');
    }

    await db.replaceCategoryForTransactions(category.id, fallback.id);
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
