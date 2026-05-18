import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/value_objects/amount.dart';
import '../../domain/value_objects/transaction_date.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this.db, this.activeProfile);

  final AppDatabase db;
  final ActiveProfileHolder activeProfile;

  @override
  Stream<List<TransactionEntity>> watchTransactions(int profileId) {
    final toAccounts = db.alias(db.accounts, 'to_accounts');
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
            leftOuterJoin(
              toAccounts,
              toAccounts.id.equalsExp(db.transactions.toAccountId),
            ),
          ])
          ..where(db.transactions.profileId.equals(profileId))
          ..orderBy([
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
        final toAccount = row.readTable(toAccounts);
        return _mapToEntity(transaction, category, account, toAccount);
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
        comment: Value(tx.comment),
        accountId: Value(tx.accountId),
        toAccountId: Value(tx.toAccountId ?? tx.accountId),
        profileId: Value(activeProfile.id),
      ),
    );
  }

  @override
  Future<void> updateTransaction(TransactionEntity tx) async {
    final existing = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(tx.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    await db.updateTransaction(
      Transaction(
        id: tx.id,
        type: _mapType(tx.type),
        amount: tx.amount.value,
        date: tx.date.value,
        categoryId: tx.categoryId,
        comment: tx.comment,
        accountId: tx.accountId,
        toAccountId: tx.toAccountId ?? tx.accountId,
        profileId: existing.profileId,
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
    Account? toAccount,
  ) {
    final type = dbTx.type == 'income'
        ? TransactionType.income
        : dbTx.type == 'expense'
        ? TransactionType.expense
        : TransactionType.transfer;

    return TransactionEntity(
      id: dbTx.id,
      type: type,
      amount: Amount(dbTx.amount),
      date: TransactionDate(dbTx.date),
      categoryId: dbTx.categoryId,
      categoryName: type == TransactionType.transfer
          ? 'Перевод'
          : category?.name ?? 'Другое',
      accountId: dbTx.accountId,
      accountName: account?.name ?? 'Дебетовая карта',
      toAccountId: dbTx.toAccountId,
      toAccountName: toAccount?.name ?? account?.name ?? 'Дебетовая карта',
      comment: dbTx.comment,
    );
  }

  String _mapType(TransactionType type) {
    if (type == TransactionType.income) {
      return 'income';
    }
    if (type == TransactionType.expense) {
      return 'expense';
    }
    return 'transfer';
  }
}
