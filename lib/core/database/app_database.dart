import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // CREATE
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  // READ (stream!)
  Stream<List<Transaction>> watchTransactions() {
    return select(transactions).watch();
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