import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/backup_data.dart';
import '../../domain/entities/parsed_file.dart';
import '../../domain/entities/parsed_import.dart';

class XlsxImportParser {
  // Листы полного бэкапа.
  static const _profilesSheet = 'Профили';
  static const _accountsSheet = 'Счета';
  static const _categoriesSheet = 'Категории';
  static const _budgetsSheet = 'Бюджеты';
  static const _budgetCategoriesSheet = 'Бюджеты-Категории';
  static const _recurringSheet = 'Регулярные';

  // Листы с транзакциями (общие для бэкапа и устаревшего формата).
  static const _expensesSheetNames = ['Расходы', 'Expenses'];
  static const _incomeSheetNames = ['Доходы', 'Income'];
  static const _transfersSheetNames = ['Переводы', 'Transfers'];

  static final DateTime _excelEpoch = DateTime(1899, 12, 30);

  /// Разбирает файл: полный бэкап (если есть лист «Профили») либо устаревший
  /// формат только с транзакциями.
  ParsedFile parse(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.containsKey(_profilesSheet)) {
      return ParsedFile.backup(_parseBackup(excel));
    }
    return ParsedFile.legacy(_parseLegacy(excel));
  }

  // ---------------------------------------------------------------------------
  // Полный бэкап
  // ---------------------------------------------------------------------------

  BackupData _parseBackup(Excel excel) {
    final profiles = <BackupProfile>[];
    final accounts = <BackupAccount>[];
    final categories = <BackupCategory>[];
    final transactions = <BackupTransaction>[];
    final budgets = <BackupBudget>[];
    final budgetCategories = <BackupBudgetCategory>[];
    final recurring = <BackupRecurring>[];

    _forEachRow(excel.tables[_profilesSheet], (row) {
      final id = _int(row, 0);
      final name = _str(row, 1);
      if (id == null || name == null) return;
      profiles.add(
        BackupProfile(sourceId: id, name: name, isActive: _bool(row, 2)),
      );
    });

    _forEachRow(excel.tables[_accountsSheet], (row) {
      final id = _int(row, 0);
      final profileId = _int(row, 1);
      final name = _str(row, 2);
      if (id == null || profileId == null || name == null) return;
      accounts.add(
        BackupAccount(
          sourceId: id,
          profileSourceId: profileId,
          name: name,
          initialBalance: _amount(row, 3) ?? 0,
          isFallback: _bool(row, 4),
        ),
      );
    });

    _forEachRow(excel.tables[_categoriesSheet], (row) {
      final id = _int(row, 0);
      final profileId = _int(row, 1);
      final name = _str(row, 2);
      final type = _str(row, 3);
      if (id == null || profileId == null || name == null || type == null) {
        return;
      }
      categories.add(
        BackupCategory(
          sourceId: id,
          profileSourceId: profileId,
          name: name,
          type: type,
          isFallback: _bool(row, 4),
        ),
      );
    });

    for (final type in ['expense', 'income']) {
      final sheet = _findSheet(
        excel,
        type == 'expense' ? _expensesSheetNames : _incomeSheetNames,
      );
      _forEachRow(sheet, (row) {
        final profileId = _int(row, 0);
        final date = _date(row, 1);
        final categoryId = _int(row, 2);
        final accountId = _int(row, 4);
        final amount = _amount(row, 6);
        if (profileId == null ||
            date == null ||
            categoryId == null ||
            accountId == null ||
            amount == null) {
          return;
        }
        transactions.add(
          BackupTransaction(
            profileSourceId: profileId,
            type: type,
            amount: amount,
            date: date,
            categorySourceId: categoryId,
            accountSourceId: accountId,
            toAccountSourceId: accountId,
            comment: _str(row, 7),
          ),
        );
      });
    }

    _forEachRow(_findSheet(excel, _transfersSheetNames), (row) {
      final profileId = _int(row, 0);
      final date = _date(row, 1);
      final fromId = _int(row, 2);
      final toId = _int(row, 4);
      final amount = _amount(row, 6);
      if (profileId == null ||
          date == null ||
          fromId == null ||
          toId == null ||
          amount == null) {
        return;
      }
      transactions.add(
        BackupTransaction(
          profileSourceId: profileId,
          type: 'transfer',
          amount: amount,
          date: date,
          categorySourceId: null,
          accountSourceId: fromId,
          toAccountSourceId: toId,
          comment: _str(row, 7),
        ),
      );
    });

    _forEachRow(excel.tables[_budgetsSheet], (row) {
      final id = _int(row, 0);
      final profileId = _int(row, 1);
      final name = _str(row, 2);
      final limit = _amount(row, 3);
      final period = _str(row, 4);
      if (id == null ||
          profileId == null ||
          name == null ||
          limit == null ||
          period == null) {
        return;
      }
      budgets.add(
        BackupBudget(
          sourceId: id,
          profileSourceId: profileId,
          name: name,
          limitAmount: limit,
          periodType: period,
          allCategories: _bool(row, 5),
        ),
      );
    });

    _forEachRow(excel.tables[_budgetCategoriesSheet], (row) {
      final budgetId = _int(row, 0);
      final categoryId = _int(row, 1);
      if (budgetId == null || categoryId == null) return;
      budgetCategories.add(
        BackupBudgetCategory(
          budgetSourceId: budgetId,
          categorySourceId: categoryId,
        ),
      );
    });

    _forEachRow(excel.tables[_recurringSheet], (row) {
      final profileId = _int(row, 0);
      final name = _str(row, 1);
      final type = _str(row, 2);
      final amount = _amount(row, 3);
      final categoryId = _int(row, 4);
      final accountId = _int(row, 6);
      final intervalUnit = _str(row, 8);
      final intervalCount = _int(row, 9);
      final startDate = _date(row, 10);
      final nextRunDate = _date(row, 11);
      if (profileId == null ||
          name == null ||
          type == null ||
          amount == null ||
          categoryId == null ||
          accountId == null ||
          intervalUnit == null ||
          intervalCount == null ||
          startDate == null ||
          nextRunDate == null) {
        return;
      }
      recurring.add(
        BackupRecurring(
          profileSourceId: profileId,
          name: name,
          type: type,
          amount: amount,
          categorySourceId: categoryId,
          accountSourceId: accountId,
          intervalUnit: intervalUnit,
          intervalCount: intervalCount,
          startDate: startDate,
          nextRunDate: nextRunDate,
          isActive: _bool(row, 12),
        ),
      );
    });

    return BackupData(
      profiles: profiles,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      budgets: budgets,
      budgetCategories: budgetCategories,
      recurring: recurring,
    );
  }

  /// Обходит строки данных листа, пропуская строку(и) заголовка автоматически:
  /// строки, где ключевые поля не парсятся, отбрасываются в самих обработчиках.
  void _forEachRow(Sheet? sheet, void Function(List<Data?> row) handle) {
    if (sheet == null) return;
    for (var i = 1; i < sheet.maxRows; i++) {
      handle(sheet.row(i));
    }
  }

  int? _int(List<Data?> row, int index) {
    final value = _cellValue(row, index);
    if (value == null) return null;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    if (value is TextCellValue) {
      return int.tryParse(value.value.toString().trim());
    }
    return int.tryParse(value.toString().trim());
  }

  bool _bool(List<Data?> row, int index) {
    final text = _str(row, index)?.toLowerCase();
    return text == 'да' ||
        text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'истина';
  }

  // ---------------------------------------------------------------------------
  // Устаревший формат (только транзакции)
  // ---------------------------------------------------------------------------

  ParsedImport _parseLegacy(Excel excel) {
    int skipped = 0;
    final expenses = <ParsedExpense>[];
    final incomes = <ParsedIncome>[];
    final transfers = <ParsedTransfer>[];

    final expensesSheet = _findSheet(excel, _expensesSheetNames);
    if (expensesSheet != null) {
      for (var i = 2; i < expensesSheet.maxRows; i++) {
        final row = expensesSheet.row(i);
        final date = _parseDate(_cellValue(row, 0));
        final category = _stringValue(_cellValue(row, 1));
        final account = _stringValue(_cellValue(row, 2));
        final amount = _parseAmount(_cellValue(row, 3));
        final comment = _stringValue(_cellValue(row, 10));

        if (date == null ||
            category == null ||
            account == null ||
            amount == null) {
          if (_rowHasAnyValue(row)) {
            skipped++;
          }
          continue;
        }

        expenses.add(
          ParsedExpense(
            date: date,
            categoryName: category,
            accountName: account,
            amount: amount,
            comment: comment,
          ),
        );
      }
    }

    final incomeSheet = _findSheet(excel, _incomeSheetNames);
    if (incomeSheet != null) {
      for (var i = 2; i < incomeSheet.maxRows; i++) {
        final row = incomeSheet.row(i);
        final date = _parseDate(_cellValue(row, 0));
        final category = _stringValue(_cellValue(row, 1));
        final account = _stringValue(_cellValue(row, 2));
        final amount = _parseAmount(_cellValue(row, 3));
        final comment = _stringValue(_cellValue(row, 10));

        if (date == null ||
            category == null ||
            account == null ||
            amount == null) {
          if (_rowHasAnyValue(row)) {
            skipped++;
          }
          continue;
        }

        incomes.add(
          ParsedIncome(
            date: date,
            categoryName: category,
            accountName: account,
            amount: amount,
            comment: comment,
          ),
        );
      }
    }

    final transfersSheet = _findSheet(excel, _transfersSheetNames);
    if (transfersSheet != null) {
      for (var i = 2; i < transfersSheet.maxRows; i++) {
        final row = transfersSheet.row(i);
        final date = _parseDate(_cellValue(row, 0));
        final fromAccount = _stringValue(_cellValue(row, 1));
        final toAccount = _stringValue(_cellValue(row, 2));
        final amount = _parseAmount(_cellValue(row, 3));
        final comment = _stringValue(_cellValue(row, 7));

        if (date == null ||
            fromAccount == null ||
            toAccount == null ||
            amount == null) {
          if (_rowHasAnyValue(row)) {
            skipped++;
          }
          continue;
        }

        transfers.add(
          ParsedTransfer(
            date: date,
            fromAccountName: fromAccount,
            toAccountName: toAccount,
            amount: amount,
            comment: comment,
          ),
        );
      }
    }

    return ParsedImport(
      expenses: expenses,
      incomes: incomes,
      transfers: transfers,
      skippedRows: skipped,
    );
  }

  // ---------------------------------------------------------------------------
  // Общие помощники
  // ---------------------------------------------------------------------------

  Sheet? _findSheet(Excel excel, List<String> names) {
    for (final name in names) {
      final sheet = excel.tables[name];
      if (sheet != null) return sheet;
    }
    return null;
  }

  String? _str(List<Data?> row, int index) =>
      _stringValue(_cellValue(row, index));

  double? _amount(List<Data?> row, int index) =>
      _parseAmount(_cellValue(row, index));

  DateTime? _date(List<Data?> row, int index) =>
      _parseDate(_cellValue(row, index));

  CellValue? _cellValue(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value;
  }

  bool _rowHasAnyValue(List<Data?> row) {
    for (final cell in row) {
      if (_stringValue(cell?.value) != null) {
        return true;
      }
      if (cell?.value != null) {
        return true;
      }
    }
    return false;
  }

  String? _stringValue(CellValue? value) {
    if (value == null) return null;
    String? text;
    if (value is TextCellValue) {
      text = value.value.toString();
    } else if (value is FormulaCellValue) {
      text = value.formula;
    } else if (value is IntCellValue) {
      text = value.value.toString();
    } else if (value is DoubleCellValue) {
      text = value.value.toString();
    } else if (value is BoolCellValue) {
      text = value.value.toString();
    } else {
      text = value.toString();
    }
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _parseAmount(CellValue? value) {
    if (value == null) return null;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is TextCellValue) {
      final raw = value.value.toString().replaceAll(',', '.').trim();
      return double.tryParse(raw);
    }
    final str = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(str);
  }

  DateTime? _parseDate(CellValue? value) {
    if (value == null) return null;

    if (value is DateCellValue) {
      return value.asDateTimeLocal();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal();
    }

    final serial = _parseAmount(value);
    if (serial == null) return null;

    final ms = (serial * Duration.millisecondsPerDay).round();
    return _excelEpoch.add(Duration(milliseconds: ms));
  }
}
