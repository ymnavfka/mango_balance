import '../entities/category.dart';
import '../repositories/category_repository.dart';

class WatchCategories {
  WatchCategories(this.repository);

  final CategoryRepository repository;

  Stream<List<CategoryEntity>> call(int profileId) {
    return repository.watchCategories(profileId);
  }
}
