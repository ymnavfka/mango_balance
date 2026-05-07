import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();
  IntColumn get profileId => integer().customConstraint(
    'REFERENCES profiles(id) NOT NULL DEFAULT 1',
  )();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();
  IntColumn get profileId => integer().customConstraint(
    'REFERENCES profiles(id) NOT NULL DEFAULT 1',
  )();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId => integer().customConstraint(
    'REFERENCES categories(id) NOT NULL DEFAULT 1',
  )();
  TextColumn get comment => text().nullable()();

  @ReferenceName('fromTransactions')
  IntColumn get accountId => integer().customConstraint(
    'REFERENCES accounts(id) NOT NULL DEFAULT 1',
  )();

  @ReferenceName('toTransactions')
  IntColumn get toAccountId => integer().customConstraint(
    'REFERENCES accounts(id) NOT NULL DEFAULT 1',
  )();

  IntColumn get profileId => integer().customConstraint(
    'REFERENCES profiles(id) NOT NULL DEFAULT 1',
  )();
}

@DriftDatabase(tables: [Transactions, Categories, Accounts, Profiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultProfile();
      await _insertStandardCategoriesForProfile(1);
      await _insertStandardAccountsForProfile(1);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categories);
        await _insertLegacyDefaultCategories();
        await m.addColumn(transactions, transactions.categoryId);
        await customStatement(
          'UPDATE transactions SET category_id = CASE WHEN type = \'income\' THEN 1 ELSE 2 END',
        );
      }

      if (from < 3) {
        await m.createTable(accounts);
        await _insertLegacyDefaultAccounts();
        await m.addColumn(transactions, transactions.accountId);
        await customStatement('UPDATE transactions SET account_id = 1');
      }

      if (from < 4) {
        await _insertTransferCategory();
        await m.addColumn(transactions, transactions.toAccountId);
        await customStatement(
          'UPDATE transactions SET to_account_id = account_id',
        );
      }

      if (from < 5) {
        await m.addColumn(transactions, transactions.comment);
      }

      if (from < 6) {
        await m.createTable(profiles);
        await _insertDefaultProfile();
        await m.addColumn(categories, categories.profileId);
        await m.addColumn(accounts, accounts.profileId);
        await m.addColumn(transactions, transactions.profileId);
        await customStatement('UPDATE categories SET profile_id = 1');
        await customStatement('UPDATE accounts SET profile_id = 1');
        await customStatement('UPDATE transactions SET profile_id = 1');
      }
    },
  );

  Future<void> _insertDefaultProfile() async {
    await into(profiles).insert(
      ProfilesCompanion.insert(name: 'Основной', isActive: const Value(true)),
    );
  }

  Future<void> _insertLegacyDefaultCategories() async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          name: 'Other (доходы)',
          type: 'income',
          isFallback: const Value(true),
        ),
        CategoriesCompanion.insert(
          name: 'Other (расходы)',
          type: 'expense',
          isFallback: const Value(true),
        ),
        CategoriesCompanion.insert(name: 'Продукты питания', type: 'expense'),
        CategoriesCompanion.insert(name: 'Транспорт', type: 'expense'),
        CategoriesCompanion.insert(name: 'Жилищные расходы', type: 'expense'),
        CategoriesCompanion.insert(
          name: 'Медицинские расходы',
          type: 'expense',
        ),
        CategoriesCompanion.insert(name: 'Развлечения', type: 'expense'),
        CategoriesCompanion.insert(name: 'Образование', type: 'expense'),
        CategoriesCompanion.insert(name: 'Шоппинг', type: 'expense'),
        CategoriesCompanion.insert(
          name: 'Подарки и благотворительность',
          type: 'expense',
        ),
        CategoriesCompanion.insert(name: 'Основной доход', type: 'income'),
        CategoriesCompanion.insert(
          name: 'Дополнительный доход',
          type: 'income',
        ),
        CategoriesCompanion.insert(name: 'Пассивный доход', type: 'income'),
        CategoriesCompanion.insert(
          name: 'Перевод',
          type: 'transfer',
          isFallback: const Value(true),
        ),
      ]);
    });
  }

  Future<void> _insertTransferCategory() async {
    final existingTransfer = await (select(
      categories,
    )..where((c) => c.type.equals('transfer'))).get();

    if (existingTransfer.isEmpty) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: 'Перевод',
          type: 'transfer',
          isFallback: const Value(true),
        ),
      );
    }
  }

  Future<void> _insertLegacyDefaultAccounts() async {
    await batch((batch) {
      batch.insertAll(accounts, [
        AccountsCompanion.insert(
          name: 'Дебетовая карта',
          isFallback: const Value(true),
        ),
        AccountsCompanion.insert(name: 'Кредитная карта'),
      ]);
    });
  }

  Future<void> _insertStandardCategoriesForProfile(int profileId) async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          name: 'Other (доходы)',
          type: 'income',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Other (расходы)',
          type: 'expense',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Продукты питания',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Транспорт',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Жилищные расходы',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Медицинские расходы',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Развлечения',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Образование',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Шоппинг',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Подарки и благотворительность',
          type: 'expense',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Основной доход',
          type: 'income',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Дополнительный доход',
          type: 'income',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Пассивный доход',
          type: 'income',
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Перевод',
          type: 'transfer',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
      ]);
    });
  }

  Future<void> _insertMinimalCategoriesForProfile(int profileId) async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          name: 'Other (доходы)',
          type: 'income',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Other (расходы)',
          type: 'expense',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
        CategoriesCompanion.insert(
          name: 'Перевод',
          type: 'transfer',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
      ]);
    });
  }

  Future<void> _insertStandardAccountsForProfile(int profileId) async {
    await batch((batch) {
      batch.insertAll(accounts, [
        AccountsCompanion.insert(
          name: 'Дебетовая карта',
          isFallback: const Value(true),
          profileId: Value(profileId),
        ),
        AccountsCompanion.insert(
          name: 'Кредитная карта',
          profileId: Value(profileId),
        ),
      ]);
    });
  }

  Future<void> _insertMinimalAccountsForProfile(int profileId) async {
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: 'Дебетовая карта',
        isFallback: const Value(true),
        profileId: Value(profileId),
      ),
    );
  }

  // Profiles
  Future<int> createProfile({
    required String name,
    required bool includeStandardData,
  }) {
    return transaction(() async {
      final profileId = await into(
        profiles,
      ).insert(ProfilesCompanion.insert(name: name));

      if (includeStandardData) {
        await _insertStandardCategoriesForProfile(profileId);
        await _insertStandardAccountsForProfile(profileId);
      } else {
        await _insertMinimalCategoriesForProfile(profileId);
        await _insertMinimalAccountsForProfile(profileId);
      }

      return profileId;
    });
  }

  Stream<List<Profile>> watchProfiles() {
    return (select(
      profiles,
    )..orderBy([(p) => OrderingTerm(expression: p.id)])).watch();
  }

  Stream<Profile?> watchActiveProfile() {
    return (select(
      profiles,
    )..where((p) => p.isActive.equals(true))).watchSingleOrNull();
  }

  Future<Profile?> activeProfile() {
    return (select(
      profiles,
    )..where((p) => p.isActive.equals(true))).getSingleOrNull();
  }

  Future<void> renameProfile(int id, String name) {
    return (update(profiles)..where((p) => p.id.equals(id))).write(
      ProfilesCompanion(name: Value(name)),
    );
  }

  Future<void> setActiveProfile(int id) {
    return transaction(() async {
      await update(
        profiles,
      ).write(const ProfilesCompanion(isActive: Value(false)));
      await (update(profiles)..where((p) => p.id.equals(id))).write(
        const ProfilesCompanion(isActive: Value(true)),
      );
    });
  }

  Future<void> deleteProfile(int id) {
    return transaction(() async {
      await (delete(transactions)..where((t) => t.profileId.equals(id))).go();
      await (delete(accounts)..where((a) => a.profileId.equals(id))).go();
      await (delete(categories)..where((c) => c.profileId.equals(id))).go();
      await (delete(profiles)..where((p) => p.id.equals(id))).go();
    });
  }

  // Categories
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Stream<List<Category>> watchCategoriesByProfile(int profileId) {
    return (select(categories)
          ..where((c) => c.profileId.equals(profileId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.type),
            (c) => OrderingTerm(expression: c.name),
          ]))
        .watch();
  }

  Future<void> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<void> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<Category?> categoryById(int id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<Category?> fallbackCategory(String type, int profileId) {
    return (select(categories)..where(
          (c) =>
              c.type.equals(type) &
              c.isFallback.equals(true) &
              c.profileId.equals(profileId),
        ))
        .getSingleOrNull();
  }

  Future<void> replaceCategoryForTransactions(
    int oldCategoryId,
    int fallbackCategoryId,
  ) {
    return (update(transactions)
          ..where((t) => t.categoryId.equals(oldCategoryId)))
        .write(TransactionsCompanion(categoryId: Value(fallbackCategoryId)));
  }

  // Accounts
  Future<int> insertAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  Stream<List<Account>> watchAccountsByProfile(int profileId) {
    return (select(accounts)
          ..where((a) => a.profileId.equals(profileId))
          ..orderBy([(a) => OrderingTerm(expression: a.name)]))
        .watch();
  }

  Future<void> updateAccount(Account account) {
    return update(accounts).replace(account);
  }

  Future<void> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  Future<Account?> accountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<Account?> fallbackAccount(int profileId) {
    return (select(accounts)..where(
          (a) => a.isFallback.equals(true) & a.profileId.equals(profileId),
        ))
        .getSingleOrNull();
  }

  Future<void> replaceAccountForTransactions(
    int oldAccountId,
    int fallbackAccountId,
  ) {
    return (update(transactions)
          ..where((t) => t.accountId.equals(oldAccountId)))
        .write(TransactionsCompanion(accountId: Value(fallbackAccountId)));
  }

  // Transactions
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Stream<List<Transaction>> watchTransactionsByProfile(int profileId) {
    return (select(transactions)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> updateTransaction(Transaction tx) {
    return update(transactions).replace(tx);
  }

  Future<void> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
