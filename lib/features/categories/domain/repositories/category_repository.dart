import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories();

  Future<void> addCategory(CategoryEntity category);

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(int id);
}
