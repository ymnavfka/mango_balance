import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/parsed_import.dart';
import '../../domain/repositories/import_repository.dart';

class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Future<ImportResult> import({
    required int profileId,
    required ParsedImport data,
  }) {
    return db.transaction(() async {
      final profile = await (db.select(
        db.profiles,
      )..where((p) => p.id.equals(profileId))).getSingleOrNull();
      if (profile == null) {
        throw Exception('Profile $profileId does not exist');
      }

      final existingCategories = await (db.select(
        db.categories,
      )..where((c) => c.profileId.equals(profileId))).get();
      final existingAccounts = await (db.select(
        db.accounts,
      )..where((a) => a.profileId.equals(profileId))).get();

      final categoryByKey = <String, int>{
        for (final c in existingCategories) _categoryKey(c.name, c.type): c.id,
      };
      final accountByName = <String, int>{
        for (final a in existingAccounts) a.name: a.id,
      };

      int createdCategories = 0;
      int createdAccounts = 0;

      Future<int> resolveCategory(String name, String type) async {
        final key = _categoryKey(name, type);
        final cached = categoryByKey[key];
        if (cached != null) return cached;

        final id = await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                name: name,
                type: type,
                profileId: Value(profileId),
              ),
            );
        categoryByKey[key] = id;
        createdCategories++;
        return id;
      }

      Future<int> resolveAccount(String name) async {
        final cached = accountByName[name];
        if (cached != null) return cached;

        final id = await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(name: name, profileId: Value(profileId)),
            );
        accountByName[name] = id;
        createdAccounts++;
        return id;
      }

      final transferCategoryId =
          categoryByKey[_categoryKey('Перевод', 'transfer')] ??
          await resolveCategory('Перевод', 'transfer');

      int imported = 0;

      for (final tx in data.expenses) {
        final categoryId = await resolveCategory(tx.categoryName, 'expense');
        final accountId = await resolveAccount(tx.accountName);
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                type: 'expense',
                amount: tx.amount,
                date: tx.date,
                categoryId: Value(categoryId),
                accountId: Value(accountId),
                toAccountId: Value(accountId),
                comment: Value(tx.comment),
                profileId: Value(profileId),
              ),
            );
        imported++;
      }

      for (final tx in data.incomes) {
        final categoryId = await resolveCategory(tx.categoryName, 'income');
        final accountId = await resolveAccount(tx.accountName);
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                type: 'income',
                amount: tx.amount,
                date: tx.date,
                categoryId: Value(categoryId),
                accountId: Value(accountId),
                toAccountId: Value(accountId),
                comment: Value(tx.comment),
                profileId: Value(profileId),
              ),
            );
        imported++;
      }

      for (final tx in data.transfers) {
        final fromId = await resolveAccount(tx.fromAccountName);
        final toId = await resolveAccount(tx.toAccountName);
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                type: 'transfer',
                amount: tx.amount,
                date: tx.date,
                categoryId: Value(transferCategoryId),
                accountId: Value(fromId),
                toAccountId: Value(toId),
                comment: Value(tx.comment),
                profileId: Value(profileId),
              ),
            );
        imported++;
      }

      return ImportResult(
        profileId: profileId,
        profileName: profile.name,
        importedTransactions: imported,
        createdCategories: createdCategories,
        createdAccounts: createdAccounts,
        skippedRows: data.skippedRows,
      );
    });
  }

  String _categoryKey(String name, String type) => '$type::$name';
}
