import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/watch_categories.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit({
    required this.watchCategoriesUseCase,
    required this.addCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(CategoryState.initial()) {
    _init();
  }

  final WatchCategories watchCategoriesUseCase;
  final AddCategory addCategoryUseCase;
  final UpdateCategory updateCategoryUseCase;
  final DeleteCategory deleteCategoryUseCase;

  void _init() {
    watchCategoriesUseCase().listen((categories) {
      emit(state.copyWith(categories: categories));
    });
  }

  Future<void> addCategory(CategoryEntity category) async {
    await addCategoryUseCase(category);
  }

  Future<void> updateCategory(CategoryEntity category) async {
    await updateCategoryUseCase(category);
  }

  Future<void> deleteCategory(int id) async {
    await deleteCategoryUseCase(id);
  }
}
