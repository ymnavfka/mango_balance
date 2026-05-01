import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Future<void> addAccount(AccountEntity account) async {
    await db.insertAccount(
      AccountsCompanion.insert(
        name: account.name.trim(),
        isFallback: Value(account.isFallback),
      ),
    );
  }

  @override
  Stream<List<AccountEntity>> watchAccounts() {
    return db.watchAccounts().map(
      (accounts) => accounts
          .map(
            (account) => AccountEntity(
              id: account.id,
              name: account.name,
              isFallback: account.isFallback,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    await db.updateAccount(
      Account(
        id: account.id,
        name: account.name.trim(),
        isFallback: account.isFallback,
      ),
    );
  }

  @override
  Future<void> deleteAccount(int id) async {
    final account = await db.accountById(id);
    if (account == null) {
      return;
    }

    if (account.isFallback) {
      throw Exception('Default account cannot be deleted');
    }

    final fallback = await db.fallbackAccount();
    if (fallback == null) {
      throw Exception('Fallback account not found');
    }

    await db.replaceAccountForTransactions(account.id, fallback.id);
    await db.deleteAccount(id);
  }
}
