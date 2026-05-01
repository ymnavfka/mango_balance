import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/value_objects/amount.dart';
import '../../domain/value_objects/transaction_date.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    final query =
        db.select(db.transactions).join([
          leftOuterJoin(
            db.categories,
            db.categories.id.equalsExp(db.transactions.categoryId),
          ),
          leftOuterJoin(
            db.accounts,
            db.accounts.id.equalsExp(db.transactions.accountId),
          ),
        ])..orderBy([
          OrderingTerm(
            expression: db.transactions.date,
            mode: OrderingMode.desc,
          ),
        ]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final transaction = row.readTable(db.transactions);
        final category = row.readTable(db.categories);
        final account = row.readTable(db.accounts);
        return _mapToEntity(transaction, category, account);
      }).toList(),
    );
  }

  @override
  Future<void> addTransaction(TransactionEntity tx) async {
    await db.insertTransaction(
      TransactionsCompanion.insert(
        type: _mapType(tx.type),
        amount: tx.amount.value,
        date: tx.date.value,
      ).copyWith(
        categoryId: Value(tx.categoryId),
        accountId: Value(tx.accountId),
      ),
    );
  }

  @override
  Future<void> updateTransaction(TransactionEntity tx) async {
    await db.updateTransaction(
      Transaction(
        id: tx.id,
        type: _mapType(tx.type),
        amount: tx.amount.value,
        date: tx.date.value,
        categoryId: tx.categoryId,
        accountId: tx.accountId,
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
  }

  TransactionEntity _mapToEntity(
    Transaction dbTx,
    Category? category,
    Account? account,
  ) {
    return TransactionEntity(
      id: dbTx.id,
      type: dbTx.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: Amount(dbTx.amount),
      date: TransactionDate(dbTx.date),
      categoryId: dbTx.categoryId,
      categoryName: category?.name ?? 'Other',
      accountId: dbTx.accountId,
      accountName: account?.name ?? 'Дебетовая карта',
    );
  }

  String _mapType(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }
}
