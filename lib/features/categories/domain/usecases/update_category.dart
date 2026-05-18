import '../entities/category.dart';
import '../repositories/category_repository.dart';

class UpdateCategory {
  UpdateCategory(this.repository);

  final CategoryRepository repository;

  Future<void> call(CategoryEntity category) async {
    if (category.name.trim().isEmpty) {
      throw Exception('Название категории не должно быть пустым');
    }

    await repository.updateCategory(category);
  }
}
