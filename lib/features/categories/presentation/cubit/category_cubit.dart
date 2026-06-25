import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/watch_categories.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit({
    required this.activeProfile,
    required this.watchCategoriesUseCase,
    required this.addCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(CategoryState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final WatchCategories watchCategoriesUseCase;
  final AddCategory addCategoryUseCase;
  final UpdateCategory updateCategoryUseCase;
  final DeleteCategory deleteCategoryUseCase;

  StreamSubscription<List<CategoryEntity>>? _categoriesSubscription;
  late final StreamSubscription<int> _profileSubscription;

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = watchCategoriesUseCase(profileId).listen((
      categories,
    ) {
      emit(state.copyWith(categories: categories));
    });
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  Future<int> addCategory(CategoryEntity category) async {
    return addCategoryUseCase(category);
  }

  Future<void> updateCategory(CategoryEntity category) async {
    await updateCategoryUseCase(category);
  }

  Future<void> deleteCategory(int id) async {
    await deleteCategoryUseCase(id);
  }
}
