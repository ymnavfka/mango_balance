import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/repositories/export_repository.dart';

/// Формирует полный XLSX-бэкап выбранных профилей: профили, счета (с начальным
/// балансом), категории, транзакции, бюджеты (со связями категорий) и
/// регулярные платежи. Связи между сущностями хранятся по исходным id, а имена
/// дублируются рядом для читаемости человеком.
class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl(this.db);

  final AppDatabase db;

  static const _profilesSheet = 'Профили';
  static const _accountsSheet = 'Счета';
  static const _categoriesSheet = 'Категории';
  static const _expensesSheet = 'Расходы';
  static const _incomeSheet = 'Доходы';
  static const _transfersSheet = 'Переводы';
  static const _budgetsSheet = 'Бюджеты';
  static const _budgetCategoriesSheet = 'Бюджеты-Категории';
  static const _recurringSheet = 'Регулярные';

  @override
  Future<ExportPayload> buildXlsx(ExportOptions options) async {
    final ids = options.profileIds;
    if (ids.isEmpty) {
      throw Exception('Не выбран ни один профиль');
    }

    final profiles =
        await (db.select(db.profiles)
              ..where((p) => p.id.isIn(ids))
              ..orderBy([(p) => OrderingTerm(expression: p.id)]))
            .get();
    if (profiles.isEmpty) {
      throw Exception('Профили не найдены');
    }

    final accounts = await (db.select(
      db.accounts,
    )..where((a) => a.profileId.isIn(ids))).get();
    final categories = await (db.select(
      db.categories,
    )..where((c) => c.profileId.isIn(ids))).get();

    final txQuery = db.select(db.transactions)
      ..where((t) => t.profileId.isIn(ids));
    final from = options.dateFrom;
    final to = options.dateTo;
    if (from != null) {
      txQuery.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      txQuery.where((t) => t.date.isSmallerOrEqualValue(to));
    }
    txQuery.orderBy([(t) => OrderingTerm(expression: t.date)]);
    final transactions = await txQuery.get();

    final budgets = await (db.select(
      db.budgets,
    )..where((b) => b.profileId.isIn(ids))).get();
    final budgetIds = budgets.map((b) => b.id).toList();
    final budgetCategories = <BudgetCategory>[];
    if (budgetIds.isNotEmpty) {
      budgetCategories.addAll(
        await (db.select(
          db.budgetCategories,
        )..where((bc) => bc.budgetId.isIn(budgetIds))).get(),
      );
    }
    final recurring = await (db.select(
      db.recurringPayments,
    )..where((r) => r.profileId.isIn(ids))).get();

    final categoryName = {for (final c in categories) c.id: c.name};
    final accountName = {for (final a in accounts) a.id: a.name};

    final excel = Excel.createExcel();
    for (final defaultName in List<String>.from(excel.tables.keys)) {
      excel.delete(defaultName);
    }

    // Профили
    excel.appendRow(_profilesSheet, [
      TextCellValue('ID'),
      TextCellValue('Название'),
      TextCellValue('Активный'),
    ]);
    for (final p in profiles) {
      excel.appendRow(_profilesSheet, [
        IntCellValue(p.id),
        TextCellValue(p.name),
        TextCellValue(_bool(p.isActive)),
      ]);
    }

    // Счета
    excel.appendRow(_accountsSheet, [
      TextCellValue('ID'),
      TextCellValue('ПрофильID'),
      TextCellValue('Название'),
      TextCellValue('Начальный баланс'),
      TextCellValue('Резервный'),
      TextCellValue('Архивный'),
    ]);
    for (final a in accounts) {
      excel.appendRow(_accountsSheet, [
        IntCellValue(a.id),
        IntCellValue(a.profileId),
        TextCellValue(a.name),
        DoubleCellValue(a.initialBalance),
        TextCellValue(_bool(a.isFallback)),
        TextCellValue(_bool(a.isArchived)),
      ]);
    }

    // Категории
    excel.appendRow(_categoriesSheet, [
      TextCellValue('ID'),
      TextCellValue('ПрофильID'),
      TextCellValue('Название'),
      TextCellValue('Тип'),
      TextCellValue('Резервный'),
      TextCellValue('Архивный'),
    ]);
    for (final c in categories) {
      excel.appendRow(_categoriesSheet, [
        IntCellValue(c.id),
        IntCellValue(c.profileId),
        TextCellValue(c.name),
        TextCellValue(c.type),
        TextCellValue(_bool(c.isFallback)),
        TextCellValue(_bool(c.isArchived)),
      ]);
    }

    // Транзакции
    const txHeader = [
      'ПрофильID',
      'Дата и время',
      'КатегорияID',
      'Категория',
      'СчётID',
      'Счёт',
      'Сумма',
      'Комментарий',
    ];
    excel.appendRow(_expensesSheet, txHeader.map(TextCellValue.new).toList());
    excel.appendRow(_incomeSheet, txHeader.map(TextCellValue.new).toList());
    excel.appendRow(_transfersSheet, [
      TextCellValue('ПрофильID'),
      TextCellValue('Дата и время'),
      TextCellValue('СчётИсточникID'),
      TextCellValue('Счёт-источник'),
      TextCellValue('СчётПолучательID'),
      TextCellValue('Счёт-получатель'),
      TextCellValue('Сумма'),
      TextCellValue('Комментарий'),
    ]);

    var transactionsCount = 0;
    for (final tx in transactions) {
      final comment = tx.comment == null ? null : TextCellValue(tx.comment!);
      switch (tx.type) {
        case 'expense':
        case 'income':
          excel
              .appendRow(tx.type == 'expense' ? _expensesSheet : _incomeSheet, [
                IntCellValue(tx.profileId),
                DateTimeCellValue.fromDateTime(tx.date),
                IntCellValue(tx.categoryId),
                TextCellValue(categoryName[tx.categoryId] ?? ''),
                IntCellValue(tx.accountId),
                TextCellValue(accountName[tx.accountId] ?? ''),
                DoubleCellValue(tx.amount),
                comment,
              ]);
          transactionsCount++;
        case 'transfer':
          excel.appendRow(_transfersSheet, [
            IntCellValue(tx.profileId),
            DateTimeCellValue.fromDateTime(tx.date),
            IntCellValue(tx.accountId),
            TextCellValue(accountName[tx.accountId] ?? ''),
            IntCellValue(tx.toAccountId),
            TextCellValue(accountName[tx.toAccountId] ?? ''),
            DoubleCellValue(tx.amount),
            comment,
          ]);
          transactionsCount++;
      }
    }

    // Бюджеты
    excel.appendRow(_budgetsSheet, [
      TextCellValue('ID'),
      TextCellValue('ПрофильID'),
      TextCellValue('Название'),
      TextCellValue('Лимит'),
      TextCellValue('Период'),
      TextCellValue('Все категории'),
    ]);
    for (final b in budgets) {
      excel.appendRow(_budgetsSheet, [
        IntCellValue(b.id),
        IntCellValue(b.profileId),
        TextCellValue(b.name),
        DoubleCellValue(b.limitAmount),
        TextCellValue(b.periodType),
        TextCellValue(_bool(b.allCategories)),
      ]);
    }

    // Бюджеты ↔ категории
    excel.appendRow(_budgetCategoriesSheet, [
      TextCellValue('БюджетID'),
      TextCellValue('КатегорияID'),
    ]);
    for (final bc in budgetCategories) {
      excel.appendRow(_budgetCategoriesSheet, [
        IntCellValue(bc.budgetId),
        IntCellValue(bc.categoryId),
      ]);
    }

    // Регулярные платежи
    excel.appendRow(_recurringSheet, [
      TextCellValue('ПрофильID'),
      TextCellValue('Название'),
      TextCellValue('Тип'),
      TextCellValue('Сумма'),
      TextCellValue('КатегорияID'),
      TextCellValue('Категория'),
      TextCellValue('СчётID'),
      TextCellValue('Счёт'),
      TextCellValue('Единица интервала'),
      TextCellValue('Шаг интервала'),
      TextCellValue('Дата начала'),
      TextCellValue('Дата следующего'),
      TextCellValue('Активен'),
    ]);
    for (final r in recurring) {
      excel.appendRow(_recurringSheet, [
        IntCellValue(r.profileId),
        TextCellValue(r.name),
        TextCellValue(r.type),
        DoubleCellValue(r.amount),
        IntCellValue(r.categoryId),
        TextCellValue(categoryName[r.categoryId] ?? ''),
        IntCellValue(r.accountId),
        TextCellValue(accountName[r.accountId] ?? ''),
        TextCellValue(r.intervalUnit),
        IntCellValue(r.intervalCount),
        DateTimeCellValue.fromDateTime(r.startDate),
        DateTimeCellValue.fromDateTime(r.nextRunDate),
        TextCellValue(_bool(r.isActive)),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Не удалось сформировать XLSX-файл');
    }

    return ExportPayload(
      bytes: Uint8List.fromList(encoded),
      profileNames: profiles.map((p) => p.name).toList(),
      transactionsCount: transactionsCount,
    );
  }

  String _bool(bool value) => value ? 'да' : 'нет';
}
