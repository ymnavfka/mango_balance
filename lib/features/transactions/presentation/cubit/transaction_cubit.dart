import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../data/datasources/date_range_filter_storage.dart';
import '../../data/datasources/transaction_type_filter_storage.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/calculate_account_balances.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/filter_transactions_by_account.dart';
import '../../domain/usecases/filter_transactions_by_date_range.dart';
import '../../domain/usecases/filter_transactions_by_type.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';
import '../helpers/transaction_section_builder.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit({
    required this.activeProfile,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.watchTransactionsUseCase,
    required this.watchAccountsUseCase,
    required this.calculateAccountBalancesUseCase,
    required this.filterTransactionsUseCase,
    required this.filterTransactionsByTypeUseCase,
    required this.filterTransactionsByDateRangeUseCase,
    required this.typeFilterStorage,
    required this.dateRangeFilterStorage,
  }) : super(TransactionState.initial()) {
    _visibleTypes = typeFilterStorage.read();
    _dateRange = dateRangeFilterStorage.read();
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final AddTransaction addTransactionUseCase;
  final UpdateTransaction updateTransactionUseCase;
  final DeleteTransaction deleteTransactionUseCase;
  final WatchTransactions watchTransactionsUseCase;
  final WatchAccounts watchAccountsUseCase;
  final CalculateAccountBalances calculateAccountBalancesUseCase;
  final FilterTransactionsByAccount filterTransactionsUseCase;
  final FilterTransactionsByType filterTransactionsByTypeUseCase;
  final FilterTransactionsByDateRange filterTransactionsByDateRangeUseCase;
  final TransactionTypeFilterStorage typeFilterStorage;
  final DateRangeFilterStorage dateRangeFilterStorage;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<List<AccountEntity>>? _accountsSubscription;
  late final StreamSubscription<int> _profileSubscription;
  List<TransactionEntity> _allTransactions = [];
  List<AccountEntity> _accounts = [];
  int? _selectedAccountId;
  late Set<TransactionType> _visibleTypes;
  late DateTimeRange? _dateRange;

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _transactionsSubscription?.cancel();
    _accountsSubscription?.cancel();

    _allTransactions = [];
    _accounts = [];
    _selectedAccountId = null;
    emit(
      TransactionState.initial().copyWith(
        visibleTypes: _visibleTypes,
        dateRange: _dateRange,
      ),
    );

    _transactionsSubscription = watchTransactionsUseCase(profileId).listen((
      list,
    ) {
      _allTransactions = list;
      _updateState();
    });

    _accountsSubscription = watchAccountsUseCase(profileId).listen((accounts) {
      _accounts = accounts;
      _updateState();
    });
  }

  @override
  Future<void> close() async {
    await _transactionsSubscription?.cancel();
    await _accountsSubscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  Future<void> addTransaction(TransactionEntity tx) async {
    await addTransactionUseCase(tx);
  }

  Future<void> updateTransaction(TransactionEntity tx) async {
    await updateTransactionUseCase(tx);
  }

  Future<void> deleteTransaction(int id) async {
    await deleteTransactionUseCase(id);
  }

  Future<void> restoreTransaction(TransactionEntity tx, int index) async {
    await addTransaction(tx);
  }

  void selectAccount(int? accountId) {
    _selectedAccountId = accountId;
    _updateState();
  }

  Future<void> toggleTransactionType(TransactionType type) async {
    final next = Set<TransactionType>.from(_visibleTypes);
    if (next.contains(type)) {
      if (next.length == 1) return;
      next.remove(type);
    } else {
      next.add(type);
    }
    _visibleTypes = next;
    await typeFilterStorage.write(next);
    _updateState();
  }

  Future<void> setDateRange(DateTimeRange? range) async {
    _dateRange = range;
    await dateRangeFilterStorage.write(range);
    _updateState();
  }

  void _updateState() {
    final initialBalances = {
      for (final account in _accounts) account.id: account.initialBalance,
    };
    final accountBalances = calculateAccountBalancesUseCase(
      _allTransactions,
      initialBalances: initialBalances,
    );
    final totalBalance = accountBalances.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final byAccount = filterTransactionsUseCase(
      _allTransactions,
      _selectedAccountId,
    );
    final byType = filterTransactionsByTypeUseCase(byAccount, _visibleTypes);
    final byDate = filterTransactionsByDateRangeUseCase(byType, _dateRange);
    final sections = TransactionSectionBuilder.buildSections(byDate);
    final selectedBalance = _selectedAccountId == null
        ? totalBalance
        : accountBalances[_selectedAccountId!] ?? 0;

    emit(
      state.copyWith(
        transactions: byDate,
        allTransactions: _allTransactions,
        sections: sections,
        selectedAccountId: _selectedAccountId,
        totalBalance: totalBalance,
        selectedBalance: selectedBalance,
        accountBalances: accountBalances,
        visibleTypes: _visibleTypes,
        dateRange: _dateRange,
      ),
    );
  }
}
