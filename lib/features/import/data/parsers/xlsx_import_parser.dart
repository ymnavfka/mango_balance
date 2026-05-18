import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/parsed_import.dart';

class XlsxImportParser {
  static const _expensesSheetNames = ['Расходы', 'Expenses'];
  static const _incomeSheetNames = ['Доходы', 'Income'];
  static const _transfersSheetNames = ['Переводы', 'Transfers'];

  static final DateTime _excelEpoch = DateTime(1899, 12, 30);

  Sheet? _findSheet(Excel excel, List<String> names) {
    for (final name in names) {
      final sheet = excel.tables[name];
      if (sheet != null) return sheet;
    }
    return null;
  }

  ParsedImport parse(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

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
