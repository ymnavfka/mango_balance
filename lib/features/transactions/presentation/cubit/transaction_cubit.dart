import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit({
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.watchTransactionsUseCase,
  }) : super(TransactionState.initial()) {
    _init();
  }

  final AddTransaction addTransactionUseCase;
  final UpdateTransaction updateTransactionUseCase;
  final DeleteTransaction deleteTransactionUseCase;
  final WatchTransactions watchTransactionsUseCase;

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

  // CREATE
  Future<void> addTransaction(TransactionEntity tx) async {
    await addTransactionUseCase(tx);
  }

  // UPDATE
  Future<void> updateTransaction(TransactionEntity tx) async {
    await updateTransactionUseCase(tx);
  }

  // DELETE
  Future<void> deleteTransaction(int id) async {
    await deleteTransactionUseCase(id);
  }

  // RESTORE
  Future<void> restoreTransaction(TransactionEntity tx, int index) async {
    await addTransaction(tx);
  }

  void selectAccount(int? accountId) {
    _selectedAccountId = accountId;
    _updateState();
  }

  void _updateState() {
    final accountBalances = _calculateAccountBalances(_allTransactions);
    final totalBalance = accountBalances.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final filteredTransactions = _filterTransactions(_allTransactions);
    final sections = _buildSections(filteredTransactions);
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

  List<TransactionEntity> _filterTransactions(
    List<TransactionEntity> transactions,
  ) {
    if (_selectedAccountId == null) {
      return transactions;
    }

    return transactions.where((tx) {
      return tx.accountId == _selectedAccountId ||
          tx.toAccountId == _selectedAccountId;
    }).toList();
  }

  Map<int, double> _calculateAccountBalances(
    List<TransactionEntity> transactions,
  ) {
    final balances = <int, double>{};

    for (final tx in transactions) {
      balances[tx.accountId] = (balances[tx.accountId] ?? 0);
      if (tx.type == TransactionType.income) {
        balances[tx.accountId] = balances[tx.accountId]! + tx.amount.value;
      } else if (tx.type == TransactionType.expense) {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
      } else {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
        if (tx.toAccountId != null) {
          balances[tx.toAccountId!] =
              (balances[tx.toAccountId!] ?? 0) + tx.amount.value;
        }
      }
    }

    return balances;
  }

  List<TransactionSection> _buildSections(
    List<TransactionEntity> transactions,
  ) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};

    for (final tx in transactions) {
      final d = tx.date.value;
      final dateKey = DateTime(d.year, d.month, d.day);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(tx);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // новые сверху

    return sortedKeys.map((date) {
      return TransactionSection(
        title: _formatSectionDate(date),
        transactions: grouped[date]!,
      );
    }).toList();
  }

  String _formatSectionDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
