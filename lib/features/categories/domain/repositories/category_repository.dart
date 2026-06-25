import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories(int profileId);

  /// Создаёт категорию и возвращает её идентификатор.
  Future<int> addCategory(CategoryEntity category);

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(int id);
}
