import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';
import '../../../../core/enums/transaction_type.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this.db) : super(TransactionState.initial()) {
    _init();
  }
  final AppDatabase db;

  void _init() {
    db.watchTransactions().listen((data) {
      final list = data.map(_mapToEntity).toList();
      final sections = _buildSections(list);

      emit(state.copyWith(transactions: list, sections: sections));
    });
  }

  TransactionEntity _mapToEntity(Transaction dbTx) {
    return TransactionEntity(
      id: dbTx.id,
      type: dbTx.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: dbTx.amount,
      date: dbTx.date,
    );
  }

  String _mapType(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }

  // CREATE
  Future<void> addTransaction(TransactionEntity tx) async {
    await db.insertTransaction(
      TransactionsCompanion.insert(
        type: _mapType(tx.type),
        amount: tx.amount,
        date: tx.date,
      ),
    );
  }

  // UPDATE
  Future<void> updateTransaction(TransactionEntity tx) async {
    await db.updateTransaction(
      Transaction(
        id: tx.id,
        type: _mapType(tx.type),
        amount: tx.amount,
        date: tx.date,
      ),
    );
  }

  // DELETE
  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
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
    final now = DateTime.now();

    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    List<TransactionEntity> today = [];
    List<TransactionEntity> yesterday = [];
    List<TransactionEntity> earlier = [];

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (txDate == todayDate) {
        today.add(tx);
      } else if (txDate == yesterdayDate) {
        yesterday.add(tx);
      } else {
        earlier.add(tx);
      }
    }

    final sections = <TransactionSection>[];

    if (today.isNotEmpty) {
      sections.add(TransactionSection(title: 'Today', transactions: today));
    }

    if (yesterday.isNotEmpty) {
      sections.add(
        TransactionSection(title: 'Yesterday', transactions: yesterday),
      );
    }

    if (earlier.isNotEmpty) {
      sections.add(TransactionSection(title: 'Earlier', transactions: earlier));
    }

    return sections;
  }
}
