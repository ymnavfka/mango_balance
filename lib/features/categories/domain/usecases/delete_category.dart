import '../repositories/category_repository.dart';

class DeleteCategory {
  DeleteCategory(this.repository);

  final CategoryRepository repository;

  Future<void> call(int id) async {
    await repository.deleteCategory(id);
  }
}
