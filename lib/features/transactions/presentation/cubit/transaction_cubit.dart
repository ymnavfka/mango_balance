import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/calculate_account_balances.dart';
import '../../domain/usecases/filter_transactions_by_account.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';
import '../helpers/transaction_section_builder.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit({
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.watchTransactionsUseCase,
    required this.calculateAccountBalancesUseCase,
    required this.filterTransactionsUseCase,
  }) : super(TransactionState.initial()) {
    _init();
  }

  final AddTransaction addTransactionUseCase;
  final UpdateTransaction updateTransactionUseCase;
  final DeleteTransaction deleteTransactionUseCase;
  final WatchTransactions watchTransactionsUseCase;
  final CalculateAccountBalances calculateAccountBalancesUseCase;
  final FilterTransactionsByAccount filterTransactionsUseCase;

  late final StreamSubscription<List<TransactionEntity>>
  _transactionsSubscription;
  List<TransactionEntity> _allTransactions = [];
  int? _selectedAccountId;

  void _init() {
    _transactionsSubscription = watchTransactionsUseCase().listen((list) {
      _allTransactions = list;
      _updateState();
    });
  }

  @override
  Future<void> close() async {
    await _transactionsSubscription.cancel();
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

  void _updateState() {
    final accountBalances = calculateAccountBalancesUseCase(_allTransactions);
    final totalBalance = accountBalances.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final filteredTransactions = filterTransactionsUseCase(
      _allTransactions,
      _selectedAccountId,
    );
    final sections = TransactionSectionBuilder.buildSections(
      filteredTransactions,
    );
    final selectedBalance = _selectedAccountId == null
        ? totalBalance
        : accountBalances[_selectedAccountId!] ?? 0;

    emit(
      state.copyWith(
        transactions: filteredTransactions,
        sections: sections,
        selectedAccountId: _selectedAccountId,
        totalBalance: totalBalance,
        selectedBalance: selectedBalance,
        accountBalances: accountBalances,
      ),
    );
  }
}
