import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this.db, this.activeProfile);

  final AppDatabase db;
  final ActiveProfileHolder activeProfile;

  @override
  Future<void> addAccount(AccountEntity account) async {
    await db.insertAccount(
      AccountsCompanion.insert(
        name: account.name.trim(),
        isFallback: Value(account.isFallback),
        initialBalance: Value(account.initialBalance),
        profileId: Value(activeProfile.id),
      ),
    );
  }

  @override
  Stream<List<AccountEntity>> watchAccounts(int profileId) {
    return db
        .watchAccountsByProfile(profileId)
        .map(
          (accounts) => accounts
              .map(
                (account) => AccountEntity(
                  id: account.id,
                  name: account.name,
                  isFallback: account.isFallback,
                  initialBalance: account.initialBalance,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    final existing = await db.accountById(account.id);
    if (existing == null) {
      return;
    }
    await db.updateAccount(
      Account(
        id: account.id,
        name: account.name.trim(),
        isFallback: account.isFallback,
        initialBalance: account.initialBalance,
        profileId: existing.profileId,
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
      throw Exception('Счёт по умолчанию нельзя удалить');
    }

    final fallback = await db.fallbackAccount(account.profileId);
    if (fallback == null) {
      throw Exception('Базовый счёт не найден');
    }

    await db.replaceAccountForTransactions(account.id, fallback.id);
    await db.replaceAccountForRecurringPayments(account.id, fallback.id);
    await db.deleteAccount(id);
  }
}
