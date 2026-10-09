import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/backup_data.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/parsed_import.dart';
import '../../domain/entities/restore_result.dart';
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
        throw Exception('Профиль $profileId не найден');
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

  @override
  Future<RestoreResult> restore(BackupData data) {
    return db.transaction(() async {
      final existing = await db.select(db.profiles).get();
      final takenProfileNames = existing.map((p) => p.name).toSet();

      final accountsByProfile = _groupBy(
        data.accounts,
        (a) => a.profileSourceId,
      );
      final categoriesByProfile = _groupBy(
        data.categories,
        (c) => c.profileSourceId,
      );
      final transactionsByProfile = _groupBy(
        data.transactions,
        (t) => t.profileSourceId,
      );
      final budgetsByProfile = _groupBy(data.budgets, (b) => b.profileSourceId);
      final recurringByProfile = _groupBy(
        data.recurring,
        (r) => r.profileSourceId,
      );

      final accountIdMap = <int, int>{};
      final categoryIdMap = <int, int>{};
      final budgetIdMap = <int, int>{};

      final createdProfileNames = <String>[];
      int importedTransactions = 0;
      int createdBudgets = 0;
      int createdRecurring = 0;

      for (final profile in data.profiles) {
        final name = _uniqueName(profile.name, takenProfileNames);
        final newProfileId = await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                name: name,
                isActive: const Value(false),
              ),
            );
        createdProfileNames.add(name);

        for (final a in accountsByProfile[profile.sourceId] ?? const []) {
          final id = await db
              .into(db.accounts)
              .insert(
                AccountsCompanion.insert(
                  name: a.name,
                  isFallback: Value(a.isFallback),
                  isArchived: Value(a.isArchived && !a.isFallback),
                  initialBalance: Value(a.initialBalance),
                  profileId: Value(newProfileId),
                ),
              );
          accountIdMap[a.sourceId] = id;
        }

        for (final c in categoriesByProfile[profile.sourceId] ?? const []) {
          final id = await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  name: c.name,
                  type: c.type,
                  isFallback: Value(c.isFallback),
                  isArchived: Value(c.isArchived && !c.isFallback),
                  profileId: Value(newProfileId),
                ),
              );
          categoryIdMap[c.sourceId] = id;
        }

        // Категория для переводов в этом профиле (переводы хранятся без ссылки).
        final transferCategoryId = await _resolveTransferCategory(
          newProfileId,
          categoriesByProfile[profile.sourceId] ?? const [],
          categoryIdMap,
        );

        for (final t in transactionsByProfile[profile.sourceId] ?? const []) {
          final accountId = accountIdMap[t.accountSourceId];
          if (accountId == null) continue;
          final toAccountId = accountIdMap[t.toAccountSourceId] ?? accountId;
          final categoryId = t.type == 'transfer'
              ? transferCategoryId
              : categoryIdMap[t.categorySourceId];
          if (categoryId == null) continue;

          await db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  type: t.type,
                  amount: t.amount,
                  date: t.date,
                  categoryId: Value(categoryId),
                  accountId: Value(accountId),
                  toAccountId: Value(toAccountId),
                  comment: Value(t.comment),
                  profileId: Value(newProfileId),
                ),
              );
          importedTransactions++;
        }

        for (final b in budgetsByProfile[profile.sourceId] ?? const []) {
          final id = await db
              .into(db.budgets)
              .insert(
                BudgetsCompanion.insert(
                  profileId: Value(newProfileId),
                  name: b.name,
                  limitAmount: b.limitAmount,
                  periodType: b.periodType,
                  allCategories: Value(b.allCategories),
                ),
              );
          budgetIdMap[b.sourceId] = id;
          createdBudgets++;
        }

        for (final r in recurringByProfile[profile.sourceId] ?? const []) {
          final categoryId = categoryIdMap[r.categorySourceId];
          final accountId = accountIdMap[r.accountSourceId];
          if (categoryId == null || accountId == null) continue;
          await db
              .into(db.recurringPayments)
              .insert(
                RecurringPaymentsCompanion.insert(
                  profileId: Value(newProfileId),
                  name: r.name,
                  type: r.type,
                  amount: r.amount,
                  categoryId: Value(categoryId),
                  accountId: Value(accountId),
                  intervalUnit: r.intervalUnit,
                  intervalCount: Value(r.intervalCount),
                  startDate: r.startDate,
                  nextRunDate: r.nextRunDate,
                  isActive: Value(r.isActive),
                ),
              );
          createdRecurring++;
        }
      }

      // Связи бюджет↔категория — после переотображения всех id.
      for (final bc in data.budgetCategories) {
        final budgetId = budgetIdMap[bc.budgetSourceId];
        final categoryId = categoryIdMap[bc.categorySourceId];
        if (budgetId == null || categoryId == null) continue;
        await db.insertBudgetCategory(budgetId, categoryId);
      }

      return RestoreResult(
        profileNames: createdProfileNames,
        importedTransactions: importedTransactions,
        createdBudgets: createdBudgets,
        createdRecurring: createdRecurring,
      );
    });
  }

  Future<int> _resolveTransferCategory(
    int newProfileId,
    List<BackupCategory> categories,
    Map<int, int> categoryIdMap,
  ) async {
    BackupCategory? chosen;
    for (final c in categories) {
      if (c.type == 'transfer') {
        if (c.isFallback) {
          chosen = c;
          break;
        }
        chosen ??= c;
      }
    }
    if (chosen != null) {
      final mapped = categoryIdMap[chosen.sourceId];
      if (mapped != null) return mapped;
    }
    // На случай бэкапа без категории переводов — создаём резервную.
    return db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: 'Перевод',
            type: 'transfer',
            isFallback: const Value(true),
            profileId: Value(newProfileId),
          ),
        );
  }

  /// Уникализация имени при коллизии: «личный» → «личный2» → «личный3»…
  /// Если имя уже оканчивается цифрой — она увеличивается на 1.
  String _uniqueName(String name, Set<String> taken) {
    var candidate = name;
    while (taken.contains(candidate)) {
      candidate = _bumpName(candidate);
    }
    taken.add(candidate);
    return candidate;
  }

  String _bumpName(String name) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(name);
    if (match != null) {
      final base = match.group(1)!;
      final number = int.parse(match.group(2)!);
      return '$base${number + 1}';
    }
    return '${name}2';
  }

  Map<int, List<T>> _groupBy<T>(List<T> items, int Function(T) key) {
    final map = <int, List<T>>{};
    for (final item in items) {
      map.putIfAbsent(key(item), () => []).add(item);
    }
    return map;
  }

  String _categoryKey(String name, String type) => '$type::$name';
}
