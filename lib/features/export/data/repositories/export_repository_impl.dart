import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/repositories/export_repository.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl(this.db);

  final AppDatabase db;

  static const _expensesSheet = 'Expenses';
  static const _incomeSheet = 'Income';
  static const _transfersSheet = 'Transfers';

  @override
  Future<ExportPayload> buildXlsx(ExportOptions options) async {
    final profile = await (db.select(
      db.profiles,
    )..where((p) => p.id.equals(options.profileId))).getSingleOrNull();
    if (profile == null) {
      throw Exception('Profile ${options.profileId} does not exist');
    }

    final toAccounts = db.alias(db.accounts, 'to_accounts');
    final query = db.select(db.transactions).join([
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
    ])..where(db.transactions.profileId.equals(options.profileId));

    final from = options.dateFrom;
    final to = options.dateTo;
    if (from != null) {
      query.where(db.transactions.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(db.transactions.date.isSmallerOrEqualValue(to));
    }
    query.orderBy([OrderingTerm(expression: db.transactions.date)]);

    final rows = await query.get();

    final excel = Excel.createExcel();
    for (final defaultName in List<String>.from(excel.tables.keys)) {
      excel.delete(defaultName);
    }

    excel.appendRow(_expensesSheet, [
      TextCellValue('Date and time'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('Amount'),
      TextCellValue('Comment'),
    ]);
    excel.appendRow(_incomeSheet, [
      TextCellValue('Date and time'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('Amount'),
      TextCellValue('Comment'),
    ]);
    excel.appendRow(_transfersSheet, [
      TextCellValue('Date and time'),
      TextCellValue('Outgoing'),
      TextCellValue('Incoming'),
      TextCellValue('Amount'),
      TextCellValue('Comment'),
    ]);

    int exportedCount = 0;

    for (final row in rows) {
      final tx = row.readTable(db.transactions);
      final category = row.readTableOrNull(db.categories);
      final account = row.readTableOrNull(db.accounts);
      final toAccount = row.readTableOrNull(toAccounts);

      switch (tx.type) {
        case 'expense':
          excel.appendRow(_expensesSheet, [
            DateTimeCellValue.fromDateTime(tx.date),
            TextCellValue(category?.name ?? ''),
            TextCellValue(account?.name ?? ''),
            DoubleCellValue(tx.amount),
            tx.comment == null ? null : TextCellValue(tx.comment!),
          ]);
          exportedCount++;
          break;
        case 'income':
          excel.appendRow(_incomeSheet, [
            DateTimeCellValue.fromDateTime(tx.date),
            TextCellValue(category?.name ?? ''),
            TextCellValue(account?.name ?? ''),
            DoubleCellValue(tx.amount),
            tx.comment == null ? null : TextCellValue(tx.comment!),
          ]);
          exportedCount++;
          break;
        case 'transfer':
          excel.appendRow(_transfersSheet, [
            DateTimeCellValue.fromDateTime(tx.date),
            TextCellValue(account?.name ?? ''),
            TextCellValue(toAccount?.name ?? ''),
            DoubleCellValue(tx.amount),
            tx.comment == null ? null : TextCellValue(tx.comment!),
          ]);
          exportedCount++;
          break;
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Failed to encode XLSX file');
    }

    return ExportPayload(
      bytes: Uint8List.fromList(encoded),
      profileName: profile.name,
      exportedTransactions: exportedCount,
    );
  }
}
