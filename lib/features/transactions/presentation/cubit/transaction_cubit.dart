import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this.repository) : super(TransactionState.initial()) {
    _init();
  }
  final TransactionRepository repository;

  void _init() {
    repository.watchTransactions().listen((list) {
      final sections = _buildSections(list);

      emit(state.copyWith(transactions: list, sections: sections));
    });
  }

  // CREATE
  Future<void> addTransaction(TransactionEntity tx) async {
    await repository.addTransaction(tx);
  }

  // UPDATE
  Future<void> updateTransaction(TransactionEntity tx) async {
    await repository.updateTransaction(tx);
  }

  // DELETE
  Future<void> deleteTransaction(int id) async {
    await repository.deleteTransaction(id);
  }

  // RESTORE
  Future<void> restoreTransaction(TransactionEntity tx, int index) async {
    await addTransaction(tx);
  }

  double calculateBalance(List<TransactionEntity> transactions) {
    double total = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }

    return total;
  }

  List<TransactionSection> _buildSections(
    List<TransactionEntity> transactions,
  ) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};

    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);

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
