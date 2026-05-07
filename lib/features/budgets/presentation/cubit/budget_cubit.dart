import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/usecases/watch_transactions.dart';
import '../../domain/entities/budget.dart';
import '../../domain/usecases/add_budget.dart';
import '../../domain/usecases/build_budgets_progress.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/update_budget.dart';
import '../../domain/usecases/watch_budgets.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit({
    required this.activeProfile,
    required this.watchBudgetsUseCase,
    required this.watchTransactionsUseCase,
    required this.watchCategoriesUseCase,
    required this.addBudgetUseCase,
    required this.updateBudgetUseCase,
    required this.deleteBudgetUseCase,
    required this.buildBudgetsProgressUseCase,
  }) : super(BudgetState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final WatchBudgets watchBudgetsUseCase;
  final WatchTransactions watchTransactionsUseCase;
  final WatchCategories watchCategoriesUseCase;
  final AddBudget addBudgetUseCase;
  final UpdateBudget updateBudgetUseCase;
  final DeleteBudget deleteBudgetUseCase;
  final BuildBudgetsProgress buildBudgetsProgressUseCase;

  StreamSubscription<List<BudgetEntity>>? _budgetsSubscription;
  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<List<CategoryEntity>>? _categoriesSubscription;
  late final StreamSubscription<int> _profileSubscription;

  List<BudgetEntity> _budgets = const [];
  List<TransactionEntity> _transactions = const [];
  List<CategoryEntity> _categories = const [];

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _budgetsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();

    _budgets = const [];
    _transactions = const [];
    _categories = const [];
    emit(BudgetState.initial());

    _budgetsSubscription = watchBudgetsUseCase(profileId).listen((list) {
      _budgets = list;
      _recompute();
    });
    _transactionsSubscription = watchTransactionsUseCase(profileId).listen((
      list,
    ) {
      _transactions = list;
      _recompute();
    });
    _categoriesSubscription = watchCategoriesUseCase(profileId).listen((list) {
      _categories = list;
      _recompute();
    });
  }

  @override
  Future<void> close() async {
    await _budgetsSubscription?.cancel();
    await _transactionsSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  Future<void> addBudget(BudgetEntity budget) async {
    await addBudgetUseCase(budget);
  }

  Future<void> updateBudget(BudgetEntity budget) async {
    await updateBudgetUseCase(budget);
  }

  Future<void> deleteBudget(int id) async {
    await deleteBudgetUseCase(id);
  }

  void _recompute() {
    final progresses = buildBudgetsProgressUseCase(
      budgets: _budgets,
      transactions: _transactions,
      categories: _categories,
      now: DateTime.now(),
    );
    emit(state.copyWith(progresses: progresses));
  }
}
