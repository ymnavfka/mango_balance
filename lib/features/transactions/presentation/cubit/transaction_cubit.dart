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

  void _init() {
    watchTransactionsUseCase().listen((list) {
      final sections = _buildSections(list);

      emit(state.copyWith(transactions: list, sections: sections));
    });
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

  double calculateBalance(List<TransactionEntity> transactions) {
    double total = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount.value;
      } else {
        total -= tx.amount.value;
      }
    }

    return total;
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
