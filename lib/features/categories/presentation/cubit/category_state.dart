import '../../domain/entities/category.dart';

class CategoryState {
  CategoryState({required this.categories});

  factory CategoryState.initial() {
    return CategoryState(categories: []);
  }

  final List<CategoryEntity> categories;

  CategoryState copyWith({List<CategoryEntity>? categories}) {
    return CategoryState(categories: categories ?? this.categories);
  }
}
