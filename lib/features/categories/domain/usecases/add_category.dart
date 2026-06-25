import '../entities/category.dart';
import '../repositories/category_repository.dart';

class AddCategory {
  AddCategory(this.repository);

  final CategoryRepository repository;

  Future<int> call(CategoryEntity category) async {
    if (category.name.trim().isEmpty) {
      throw Exception('Название категории не должно быть пустым');
    }

    return repository.addCategory(category);
  }
}
