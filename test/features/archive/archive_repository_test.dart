import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/database/app_database.dart';
import 'package:mango_balance/core/services/active_profile_holder.dart';
import 'package:mango_balance/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:mango_balance/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mango_balance/features/export/data/repositories/export_repository_impl.dart';
import 'package:mango_balance/features/export/domain/entities/export_options.dart';
import 'package:mango_balance/features/import/data/parsers/xlsx_import_parser.dart';
import 'package:mango_balance/features/import/data/repositories/import_repository_impl.dart';

void main() {
  // Each fixture uses a separate in-memory or temporary-file executor.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  late AppDatabase db;
  late ActiveProfileHolder profile;
  late AccountRepositoryImpl accounts;
  late CategoryRepositoryImpl categories;
  late int accountId;
  late int categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profile = ActiveProfileHolder(initialId: 1);
    accounts = AccountRepositoryImpl(db, profile);
    categories = CategoryRepositoryImpl(db, profile);
    accountId = await db.insertAccount(
      AccountsCompanion.insert(
        name: 'Savings',
        initialBalance: const Value(100),
      ),
    );
    categoryId = await db.insertCategory(
      CategoriesCompanion.insert(name: 'Gifts', type: 'expense'),
    );
    final fallback = (await db.fallbackAccount(1))!;
    await db.insertTransaction(
      TransactionsCompanion.insert(
        type: 'transfer',
        amount: 20,
        date: DateTime(2026),
        accountId: Value(fallback.id),
        toAccountId: Value(accountId),
        categoryId: Value(categoryId),
      ),
    );
    await db.insertRecurringPayment(
      RecurringPaymentsCompanion.insert(
        name: 'Gift',
        type: 'expense',
        amount: 10,
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        intervalUnit: 'year',
        startDate: DateTime(2026),
        nextRunDate: DateTime(2027),
      ),
    );
    final budget = await db.insertBudget(
      BudgetsCompanion.insert(
        name: 'Gifts',
        limitAmount: 100,
        periodType: 'month',
      ),
    );
    await db.insertBudgetCategory(budget, categoryId);
  });

  tearDown(() async {
    await db.close();
    await profile.close();
  });

  test(
    'archive and restore preserve balances, history, recurring and budget links',
    () async {
      final beforeTransactions = await db.select(db.transactions).get();
      final beforeRecurring = await db.select(db.recurringPayments).get();
      final beforeBudgets = await db.select(db.budgetCategories).get();
      final account = (await accounts.watchAccounts(1).first).firstWhere(
        (a) => a.id == accountId,
      );
      final category = (await categories.watchCategories(1).first).firstWhere(
        (c) => c.id == categoryId,
      );
      await accounts.updateAccount(account.copyWith(isArchived: true));
      await categories.updateCategory(category.copyWith(isArchived: true));
      expect((await db.accountById(accountId))!.isArchived, isTrue);
      expect((await db.accountById(accountId))!.initialBalance, 100);
      expect((await db.categoryById(categoryId))!.isArchived, isTrue);
      expect(await db.select(db.transactions).get(), beforeTransactions);
      expect(await db.select(db.recurringPayments).get(), beforeRecurring);
      expect(await db.select(db.budgetCategories).get(), beforeBudgets);
      await accounts.updateAccount(account);
      await categories.updateCategory(category);
      expect((await db.accountById(accountId))!.isArchived, isFalse);
      expect((await db.categoryById(categoryId))!.isArchived, isFalse);
    },
  );

  test(
    'deletion moves references to same-profile fallback and removes budget membership',
    () async {
      await db.createProfile(name: 'Other', includeStandardData: false);
      final fallbackAccount = (await db.fallbackAccount(1))!;
      final fallbackCategory = (await db.fallbackCategory('expense', 1))!;
      await accounts.deleteAccount(accountId);
      await categories.deleteCategory(categoryId);
      final transaction = await db.select(db.transactions).getSingle();
      final recurring = await db.select(db.recurringPayments).getSingle();
      expect(transaction.accountId, fallbackAccount.id);
      expect(transaction.toAccountId, fallbackAccount.id);
      expect(transaction.categoryId, fallbackCategory.id);
      expect(recurring.accountId, fallbackAccount.id);
      expect(recurring.categoryId, fallbackCategory.id);
      expect(await db.select(db.budgetCategories).get(), isEmpty);
      expect(await db.accountById(accountId), isNull);
      expect(await db.categoryById(categoryId), isNull);
    },
  );

  test('failed deletion rolls back all reference changes', () async {
    await db.customStatement(
      "CREATE TRIGGER reject_delete BEFORE DELETE ON accounts BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(accounts.deleteAccount(accountId), throwsA(anything));
    expect(
      (await db.select(db.transactions).getSingle()).toAccountId,
      accountId,
    );
    expect(
      (await db.select(db.recurringPayments).getSingle()).accountId,
      accountId,
    );
    expect(await db.accountById(accountId), isNotNull);
  });

  test('fallback objects cannot be archived or deleted', () async {
    final account = (await accounts.watchAccounts(1).first).firstWhere(
      (a) => a.isFallback,
    );
    final category = (await categories.watchCategories(1).first).firstWhere(
      (c) => c.isFallback,
    );
    await expectLater(
      accounts.updateAccount(account.copyWith(isArchived: true)),
      throwsException,
    );
    await expectLater(
      categories.updateCategory(category.copyWith(isArchived: true)),
      throwsException,
    );
    await expectLater(accounts.deleteAccount(account.id), throwsException);
    await expectLater(categories.deleteCategory(category.id), throwsException);
  });

  test(
    'backup retains archive flags and old backup files default to active',
    () async {
      final account = (await accounts.watchAccounts(1).first).firstWhere(
        (a) => a.id == accountId,
      );
      final category = (await categories.watchCategories(1).first).firstWhere(
        (c) => c.id == categoryId,
      );
      await accounts.updateAccount(account.copyWith(isArchived: true));
      await categories.updateCategory(category.copyWith(isArchived: true));
      final payload = await ExportRepositoryImpl(db).buildXlsx(
        const ExportOptions(profileIds: [1], dateFrom: null, dateTo: null),
      );
      final backup = XlsxImportParser()
          .parse(Uint8List.fromList(payload.bytes))
          .backup!;
      expect(
        backup.accounts.firstWhere((a) => a.sourceId == accountId).isArchived,
        isTrue,
      );
      expect(
        backup.categories
            .firstWhere((c) => c.sourceId == categoryId)
            .isArchived,
        isTrue,
      );
      await ImportRepositoryImpl(db).restore(backup);
      final restoredAccounts = await db.select(db.accounts).get();
      final restoredCategories = await db.select(db.categories).get();
      expect(
        restoredAccounts
            .where((a) => a.profileId != 1 && a.name == 'Savings')
            .single
            .isArchived,
        isTrue,
      );
      expect(
        restoredCategories
            .where((c) => c.profileId != 1 && c.name == 'Gifts')
            .single
            .isArchived,
        isTrue,
      );
      final legacy = Excel.decodeBytes(payload.bytes);
      legacy['Счета'].removeColumn(5);
      legacy['Категории'].removeColumn(5);
      final oldBackup = XlsxImportParser()
          .parse(Uint8List.fromList(legacy.encode()!))
          .backup!;
      expect(oldBackup.accounts.every((a) => !a.isArchived), isTrue);
      expect(oldBackup.categories.every((c) => !c.isArchived), isTrue);
    },
  );

  test(
    'version 11 migration keeps existing data and defaults to active',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'archive_migration_',
      );
      final file = File('${directory.path}/test.sqlite');
      final old = AppDatabase.forTesting(NativeDatabase(file));
      await old.insertAccount(
        AccountsCompanion.insert(
          name: 'Existing',
          initialBalance: const Value(321),
        ),
      );
      await old.customStatement('ALTER TABLE accounts DROP COLUMN is_archived');
      await old.customStatement(
        'ALTER TABLE categories DROP COLUMN is_archived',
      );
      await old.customStatement('PRAGMA user_version = 11');
      await old.close();
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final rows = await upgraded.select(upgraded.accounts).get();
        expect(
          rows.firstWhere((a) => a.name == 'Existing').initialBalance,
          321,
        );
        expect(rows.every((a) => !a.isArchived), isTrue);
        expect(
          (await upgraded.select(upgraded.categories).get()).every(
            (c) => !c.isArchived,
          ),
          isTrue,
        );
      } finally {
        await upgraded.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
