import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();
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
}

@DriftDatabase(tables: [Transactions, Categories, Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultCategories();
      await _insertDefaultAccounts();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categories);
        await _insertDefaultCategories();
        await m.addColumn(transactions, transactions.categoryId);
        await customStatement(
          'UPDATE transactions SET category_id = CASE WHEN type = \'income\' THEN 1 ELSE 2 END',
        );
      }

      if (from < 3) {
        await m.createTable(accounts);
        await _insertDefaultAccounts();
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
    },
  );

  Future<void> _insertDefaultCategories() async {
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

  Future<void> _insertDefaultAccounts() async {
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

  // Categories
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Stream<List<Category>> watchCategories() {
    return (select(categories)..orderBy([
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

  Future<Category?> fallbackCategory(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type) & c.isFallback.equals(true)))
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

  Stream<List<Account>> watchAccounts() {
    return (select(
      accounts,
    )..orderBy([(a) => OrderingTerm(expression: a.name)])).watch();
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

  Future<Account?> fallbackAccount() {
    return (select(
      accounts,
    )..where((a) => a.isFallback.equals(true))).getSingleOrNull();
  }

  Future<void> replaceAccountForTransactions(
    int oldAccountId,
    int fallbackAccountId,
  ) {
    return (update(transactions)
          ..where((t) => t.accountId.equals(oldAccountId)))
        .write(TransactionsCompanion(accountId: Value(fallbackAccountId)));
  }

  // CREATE
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  // READ (stream!)
  Stream<List<Transaction>> watchTransactions() {
    return (select(transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // UPDATE
  Future<void> updateTransaction(Transaction tx) {
    return update(transactions).replace(tx);
  }

  // DELETE
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
