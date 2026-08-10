// Генератор демонстрационного бэкапа для скриншотов в сторе.
// Формат совпадает с ExportRepositoryImpl, поэтому файл принимается импортом
// как полный бэкап и создаёт отдельные профили рядом с существующими данными.
//
// Запуск: dart run tool/gen_demo_backup.dart <путь_к_файлу.xlsx>

import 'dart:io';
import 'dart:math';

import 'package:excel/excel.dart';

const profilesSheet = 'Профили';
const accountsSheet = 'Счета';
const categoriesSheet = 'Категории';
const expensesSheet = 'Расходы';
const incomeSheet = 'Доходы';
const transfersSheet = 'Переводы';
const budgetsSheet = 'Бюджеты';
const budgetCategoriesSheet = 'Бюджеты-Категории';
const recurringSheet = 'Регулярные';

/// «Сегодня» для демо-данных: последняя операция — за этот день.
final today = DateTime(2026, 8, 10);

final rnd = Random(20260810);

class Acc {
  const Acc(this.id, this.profile, this.name, this.initial, {this.fb = false});
  final int id;
  final int profile;
  final String name;
  final double initial;
  final bool fb;
}

class Cat {
  const Cat(this.id, this.profile, this.name, this.type, {this.fb = false});
  final int id;
  final int profile;
  final String name;
  final String type;
  final bool fb;
}

class Tx {
  Tx(this.profile, this.date, this.cat, this.acc, this.amount, this.comment);
  final int profile;
  final DateTime date;
  final int cat;
  final int acc;
  final double amount;
  final String? comment;
}

class Tr {
  Tr(this.profile, this.date, this.from, this.to, this.amount, this.comment);
  final int profile;
  final DateTime date;
  final int from;
  final int to;
  final double amount;
  final String? comment;
}

const accounts = <Acc>[
  Acc(1, 1, 'Основная карта', 84200, fb: true),
  Acc(2, 1, 'Наличные', 6500),
  Acc(3, 1, 'Накопления', 250000),
  Acc(4, 2, 'Семейный счёт', 45000, fb: true),
  Acc(5, 2, 'Наличные', 12000),
];

const categories = <Cat>[
  Cat(1, 1, 'Продукты', 'expense'),
  Cat(2, 1, 'Кафе и рестораны', 'expense'),
  Cat(3, 1, 'Транспорт', 'expense'),
  Cat(4, 1, 'Жильё', 'expense'),
  Cat(5, 1, 'Здоровье', 'expense'),
  Cat(6, 1, 'Развлечения', 'expense'),
  Cat(7, 1, 'Одежда', 'expense'),
  Cat(8, 1, 'Подписки', 'expense'),
  Cat(9, 1, 'Другое (расходы)', 'expense', fb: true),
  Cat(10, 1, 'Зарплата', 'income'),
  Cat(11, 1, 'Фриланс', 'income'),
  Cat(12, 1, 'Кэшбэк', 'income'),
  Cat(13, 1, 'Другое (доходы)', 'income', fb: true),
  Cat(14, 1, 'Перевод', 'transfer', fb: true),
  Cat(15, 2, 'Продукты', 'expense'),
  Cat(16, 2, 'Коммунальные услуги', 'expense'),
  Cat(17, 2, 'Дети', 'expense'),
  Cat(18, 2, 'Дом и ремонт', 'expense'),
  Cat(19, 2, 'Другое (расходы)', 'expense', fb: true),
  Cat(20, 2, 'Общий бюджет', 'income'),
  Cat(21, 2, 'Другое (доходы)', 'income', fb: true),
  Cat(22, 2, 'Перевод', 'transfer', fb: true),
];

/// Комментарии подобраны так, чтобы список операций читался как настоящий.
const comments = <int, List<String>>{
  1: [
    'Супермаркет у дома',
    'Овощи и фрукты',
    'Большая закупка',
    'Пекарня',
    'Молочка и яйца',
    'Мясо на неделю',
  ],
  2: [
    'Обед с коллегами',
    'Кофе и десерт',
    'Ужин в пятницу',
    'Доставка пиццы',
    'Завтрак в кофейне',
    'Бизнес-ланч',
  ],
  3: [
    'Проездной на месяц',
    'Такси до дома',
    'Заправка',
    'Каршеринг',
    'Такси в аэропорт',
  ],
  4: ['Аренда квартиры', 'Интернет и ТВ', 'Электричество', 'Вода и отопление'],
  5: ['Аптека', 'Приём у стоматолога', 'Анализы', 'Витамины'],
  6: ['Кино с друзьями', 'Концерт', 'Книги', 'Настольные игры', 'Выставка'],
  7: ['Кроссовки', 'Футболка', 'Куртка на осень', 'Джинсы'],
  8: ['Музыка', 'Онлайн-кинотеатр', 'Облачное хранилище'],
  10: ['Зарплата за месяц', 'Аванс'],
  11: ['Проект на фрилансе', 'Консультация', 'Правки по макету'],
  12: ['Кэшбэк по карте', 'Возврат за подписку'],
  15: ['Закупка на неделю', 'Рынок', 'Супермаркет'],
  16: ['Квартплата', 'Электричество', 'Интернет'],
  17: ['Кружок по рисованию', 'Школьная форма', 'Игрушки', 'Секция плавания'],
  18: ['Лампочки и мелочи', 'Средства для уборки', 'Постельное бельё'],
  20: ['Пополнение общего бюджета'],
};

String pick(int cat) {
  final list = comments[cat];
  if (list == null || list.isEmpty) return '';
  return list[rnd.nextInt(list.length)];
}

final expenses = <Tx>[];
final incomes = <Tx>[];
final transfers = <Tr>[];

void spend(DateTime d, int cat, int acc, double amount, [String? c]) =>
    expenses.add(Tx(cat >= 15 ? 2 : 1, d, cat, acc, amount, c ?? pick(cat)));

void earn(DateTime d, int cat, int acc, double amount, [String? c]) =>
    incomes.add(Tx(cat >= 15 ? 2 : 1, d, cat, acc, amount, c ?? pick(cat)));

/// Раскидывает месячную сумму [total] по [count] операциям в пределах месяца.
void spread(int year, int month, int cat, int acc, double total, int count) {
  final lastDay = DateTime(year, month + 1, 0).day;
  var left = total;
  for (var i = 0; i < count; i++) {
    final isLast = i == count - 1;
    final share = isLast
        ? left
        : (total / count * (0.6 + rnd.nextDouble() * 0.8) / 10).round() * 10.0;
    final amount = isLast ? left : min(share, left - (count - i - 1) * 50);
    if (amount <= 0) continue;
    left -= amount;
    final day = 1 + rnd.nextInt(lastDay);
    spend(
      DateTime(year, month, day, 9 + rnd.nextInt(11), rnd.nextInt(60) ~/ 5 * 5),
      cat,
      acc,
      amount,
    );
  }
}

void buildProfile1() {
  // --- Май, июнь, июль: фон для графиков динамики ---
  const monthly = <int, Map<int, double>>{
    5: {1: 21400, 2: 9800, 3: 4300, 5: 3500, 6: 5200, 7: 7800},
    6: {1: 23900, 2: 11200, 3: 3900, 5: 1900, 6: 8400, 7: 3200},
    7: {1: 26700, 2: 12600, 3: 5100, 5: 6300, 6: 9100, 7: 5600},
  };
  const counts = <int, int>{1: 7, 2: 5, 3: 3, 5: 2, 6: 3, 7: 2};

  for (final entry in monthly.entries) {
    final m = entry.key;
    for (final c in entry.value.entries) {
      // Наличными платим только за транспорт — иначе счёт уходит в минус.
      final acc = c.key == 3 ? 2 : 1;
      spread(2026, m, c.key, acc, c.value, counts[c.key]!);
    }
    // Регулярные траты месяца.
    spend(DateTime(2026, m, 5, 10, 0), 4, 1, 38000, 'Аренда квартиры');
    spend(DateTime(2026, m, 12, 11, 0), 4, 1, 700, 'Интернет и ТВ');
    spend(DateTime(2026, m, 15, 8, 30), 8, 1, 299, 'Музыка');
    spend(DateTime(2026, m, 6, 8, 30), 8, 1, 599, 'Онлайн-кинотеатр');

    earn(DateTime(2026, m, 5, 12, 0), 10, 1, 145000, 'Зарплата за месяц');
    earn(
      DateTime(2026, m, 18, 16, 0),
      11,
      1,
      [18000.0, 24000.0, 31000.0][m - 5],
      'Проект на фрилансе',
    );
    earn(
      DateTime(2026, m, 28, 10, 0),
      12,
      1,
      [980.0, 1340.0, 1120.0][m - 5],
      'Кэшбэк по карте',
    );

    transfers.add(
      Tr(
        1,
        DateTime(2026, m, 6, 13, 0),
        1,
        3,
        [25000.0, 30000.0, 20000.0][m - 5],
        'Откладываю с зарплаты',
      ),
    );
    transfers.add(
      Tr(1, DateTime(2026, m, 20, 18, 0), 1, 2, 5000, 'Снял наличные'),
    );
  }

  // --- Август 1–10: суммы выверены под прогресс бюджетов ---
  const aug = <List<Object>>[
    [1, 1, 1, 2340.0, 'Супермаркет у дома'],
    [1, 3, 2, 1890.0, 'Овощи и фрукты'],
    [1, 5, 1, 3120.0, 'Большая закупка'],
    [1, 7, 1, 2450.0, 'Молочка и яйца'],
    [1, 9, 2, 4200.0, 'Мясо на неделю'],
    [1, 10, 1, 4500.0, 'Закупка на выходные'],
    [2, 2, 1, 1250.0, 'Обед с коллегами'],
    [2, 4, 1, 890.0, 'Кофе и десерт'],
    [2, 6, 1, 2400.0, 'Ужин в пятницу'],
    [2, 8, 1, 1100.0, 'Доставка пиццы'],
    [2, 9, 1, 1560.0, 'Завтрак в кофейне'],
    [3, 1, 1, 1500.0, 'Проездной на месяц'],
    [3, 4, 1, 420.0, 'Такси до дома'],
    [3, 7, 2, 380.0, 'Такси до дома'],
    [4, 5, 1, 38000.0, 'Аренда квартиры'],
    [5, 9, 1, 2800.0, 'Аптека'],
    [6, 8, 1, 1800.0, 'Кино с друзьями'],
    [7, 10, 1, 4900.0, 'Кроссовки'],
    [8, 3, 1, 299.0, 'Музыка'],
    [8, 6, 1, 599.0, 'Онлайн-кинотеатр'],
  ];
  for (final r in aug) {
    spend(
      DateTime(2026, 8, r[1] as int, 10 + rnd.nextInt(9), rnd.nextInt(12) * 5),
      r[0] as int,
      r[2] as int,
      r[3] as double,
      r[4] as String,
    );
  }

  earn(DateTime(2026, 8, 5, 12, 0), 10, 1, 145000, 'Зарплата за месяц');
  earn(DateTime(2026, 8, 3, 15, 0), 11, 1, 28000, 'Проект на фрилансе');
  earn(DateTime(2026, 8, 8, 9, 0), 12, 1, 1240, 'Кэшбэк по карте');

  transfers.add(
    Tr(1, DateTime(2026, 8, 2, 19, 0), 1, 2, 5000, 'Снял наличные'),
  );
  transfers.add(
    Tr(1, DateTime(2026, 8, 6, 13, 0), 1, 3, 30000, 'Откладываю с зарплаты'),
  );
}

void buildProfile2() {
  for (var m = 6; m <= 8; m++) {
    final maxDay = m == 8 ? 9 : 28;
    spread2(2026, m, 15, 4, m == 8 ? 9800 : 18500, m == 8 ? 4 : 6, maxDay);
    spend(DateTime(2026, m, 10, 12, 0), 16, 4, 7400 + m * 120.0, 'Квартплата');
    spend(
      DateTime(2026, m, min(14, maxDay), 17, 0),
      17,
      4,
      m == 8 ? 3200 : 5600,
      'Кружок по рисованию',
    );
    if (m != 8) {
      spend(DateTime(2026, m, 22, 15, 0), 18, 5, 2400, 'Средства для уборки');
    }
    earn(
      DateTime(2026, m, 5, 12, 0),
      20,
      4,
      60000,
      'Пополнение общего бюджета',
    );
  }
}

void spread2(
  int y,
  int m,
  int cat,
  int acc,
  double total,
  int count,
  int maxDay,
) {
  var left = total;
  for (var i = 0; i < count; i++) {
    final isLast = i == count - 1;
    final amount = isLast
        ? left
        : (total / count * (0.7 + rnd.nextDouble() * 0.6) / 10).round() * 10.0;
    if (amount <= 0 || (!isLast && amount >= left)) continue;
    left -= amount;
    spend(
      DateTime(y, m, 1 + rnd.nextInt(maxDay), 11 + rnd.nextInt(9), 0),
      cat,
      acc,
      amount,
    );
  }
}

String yn(bool v) => v ? 'да' : 'нет';

void main(List<String> args) {
  final out = args.isNotEmpty ? args.first : 'demo_backup.xlsx';

  buildProfile1();
  buildProfile2();
  expenses.sort((a, b) => a.date.compareTo(b.date));
  incomes.sort((a, b) => a.date.compareTo(b.date));
  transfers.sort((a, b) => a.date.compareTo(b.date));

  final excel = Excel.createExcel();
  for (final name in List<String>.from(excel.tables.keys)) {
    excel.delete(name);
  }

  excel.appendRow(
    profilesSheet,
    ['ID', 'Название', 'Активный'].map(TextCellValue.new).toList(),
  );
  excel.appendRow(profilesSheet, [
    const IntCellValue(1),
    TextCellValue('Личный'),
    TextCellValue('да'),
  ]);
  excel.appendRow(profilesSheet, [
    const IntCellValue(2),
    TextCellValue('Семейный'),
    TextCellValue('нет'),
  ]);

  excel.appendRow(
    accountsSheet,
    [
      'ID',
      'ПрофильID',
      'Название',
      'Начальный баланс',
      'Резервный',
    ].map(TextCellValue.new).toList(),
  );
  for (final a in accounts) {
    excel.appendRow(accountsSheet, [
      IntCellValue(a.id),
      IntCellValue(a.profile),
      TextCellValue(a.name),
      DoubleCellValue(a.initial),
      TextCellValue(yn(a.fb)),
    ]);
  }

  excel.appendRow(
    categoriesSheet,
    [
      'ID',
      'ПрофильID',
      'Название',
      'Тип',
      'Резервный',
    ].map(TextCellValue.new).toList(),
  );
  for (final c in categories) {
    excel.appendRow(categoriesSheet, [
      IntCellValue(c.id),
      IntCellValue(c.profile),
      TextCellValue(c.name),
      TextCellValue(c.type),
      TextCellValue(yn(c.fb)),
    ]);
  }

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
  excel.appendRow(expensesSheet, txHeader.map(TextCellValue.new).toList());
  excel.appendRow(incomeSheet, txHeader.map(TextCellValue.new).toList());
  excel.appendRow(
    transfersSheet,
    [
      'ПрофильID',
      'Дата и время',
      'СчётИсточникID',
      'Счёт-источник',
      'СчётПолучательID',
      'Счёт-получатель',
      'Сумма',
      'Комментарий',
    ].map(TextCellValue.new).toList(),
  );

  final catName = {for (final c in categories) c.id: c.name};
  final accName = {for (final a in accounts) a.id: a.name};

  void writeTx(String sheet, Tx t) {
    excel.appendRow(sheet, [
      IntCellValue(t.profile),
      DateTimeCellValue.fromDateTime(t.date),
      IntCellValue(t.cat),
      TextCellValue(catName[t.cat] ?? ''),
      IntCellValue(t.acc),
      TextCellValue(accName[t.acc] ?? ''),
      DoubleCellValue(t.amount),
      t.comment == null ? null : TextCellValue(t.comment!),
    ]);
  }

  for (final t in expenses) {
    writeTx(expensesSheet, t);
  }
  for (final t in incomes) {
    writeTx(incomeSheet, t);
  }
  for (final t in transfers) {
    excel.appendRow(transfersSheet, [
      IntCellValue(t.profile),
      DateTimeCellValue.fromDateTime(t.date),
      IntCellValue(t.from),
      TextCellValue(accName[t.from] ?? ''),
      IntCellValue(t.to),
      TextCellValue(accName[t.to] ?? ''),
      DoubleCellValue(t.amount),
      t.comment == null ? null : TextCellValue(t.comment!),
    ]);
  }

  excel.appendRow(
    budgetsSheet,
    [
      'ID',
      'ПрофильID',
      'Название',
      'Лимит',
      'Период',
      'Все категории',
    ].map(TextCellValue.new).toList(),
  );
  const budgets = <List<Object>>[
    [1, 1, 'Продукты', 25000.0, 'month', false],
    [2, 1, 'Кафе и доставка', 8000.0, 'month', false],
    [3, 1, 'Развлечения и одежда', 15000.0, 'month', false],
    [4, 1, 'Все расходы', 110000.0, 'month', true],
    [5, 2, 'Расходы семьи', 40000.0, 'month', true],
  ];
  for (final b in budgets) {
    excel.appendRow(budgetsSheet, [
      IntCellValue(b[0] as int),
      IntCellValue(b[1] as int),
      TextCellValue(b[2] as String),
      DoubleCellValue(b[3] as double),
      TextCellValue(b[4] as String),
      TextCellValue(yn(b[5] as bool)),
    ]);
  }

  excel.appendRow(
    budgetCategoriesSheet,
    ['БюджетID', 'КатегорияID'].map(TextCellValue.new).toList(),
  );
  for (final link in const [
    [1, 1],
    [2, 2],
    [3, 6],
    [3, 7],
  ]) {
    excel.appendRow(budgetCategoriesSheet, [
      IntCellValue(link[0]),
      IntCellValue(link[1]),
    ]);
  }

  excel.appendRow(
    recurringSheet,
    [
      'ПрофильID',
      'Название',
      'Тип',
      'Сумма',
      'КатегорияID',
      'Категория',
      'СчётID',
      'Счёт',
      'Единица интервала',
      'Шаг интервала',
      'Дата начала',
      'Дата следующего',
      'Активен',
    ].map(TextCellValue.new).toList(),
  );
  final recurring = <List<Object>>[
    [
      1,
      'Аренда квартиры',
      'expense',
      38000.0,
      4,
      1,
      'month',
      1,
      DateTime(2026, 1, 5),
      DateTime(2026, 9, 5),
      true,
    ],
    [
      1,
      'Интернет и ТВ',
      'expense',
      700.0,
      4,
      1,
      'month',
      1,
      DateTime(2026, 1, 12),
      DateTime(2026, 8, 12),
      true,
    ],
    [
      1,
      'Подписка на музыку',
      'expense',
      299.0,
      8,
      1,
      'month',
      1,
      DateTime(2026, 2, 15),
      DateTime(2026, 8, 15),
      true,
    ],
    [
      1,
      'Онлайн-кинотеатр',
      'expense',
      599.0,
      8,
      1,
      'month',
      1,
      DateTime(2026, 3, 6),
      DateTime(2026, 9, 6),
      true,
    ],
    [
      1,
      'Абонемент в зал',
      'expense',
      3200.0,
      5,
      1,
      'month',
      1,
      DateTime(2026, 4, 1),
      DateTime(2026, 9, 1),
      true,
    ],
    [
      1,
      'Зарплата',
      'income',
      145000.0,
      10,
      1,
      'month',
      1,
      DateTime(2026, 1, 5),
      DateTime(2026, 9, 5),
      true,
    ],
    [
      2,
      'Квартплата',
      'expense',
      7900.0,
      16,
      4,
      'month',
      1,
      DateTime(2026, 1, 10),
      DateTime(2026, 9, 10),
      true,
    ],
  ];
  for (final r in recurring) {
    excel.appendRow(recurringSheet, [
      IntCellValue(r[0] as int),
      TextCellValue(r[1] as String),
      TextCellValue(r[2] as String),
      DoubleCellValue(r[3] as double),
      IntCellValue(r[4] as int),
      TextCellValue(catName[r[4] as int] ?? ''),
      IntCellValue(r[5] as int),
      TextCellValue(accName[r[5] as int] ?? ''),
      TextCellValue(r[6] as String),
      IntCellValue(r[7] as int),
      DateTimeCellValue.fromDateTime(r[8] as DateTime),
      DateTimeCellValue.fromDateTime(r[9] as DateTime),
      TextCellValue(yn(r[10] as bool)),
    ]);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    stderr.writeln('Не удалось сформировать файл');
    exit(1);
  }
  File(out).writeAsBytesSync(bytes);

  double sum(Iterable<Tx> xs, bool Function(Tx) w) =>
      xs.where(w).fold(0.0, (a, t) => a + t.amount);
  bool aug(Tx t) => t.date.month == 8 && t.profile == 1;

  stdout.writeln('Файл: $out');
  stdout.writeln(
    'Расходы: ${expenses.length}, доходы: ${incomes.length}, '
    'переводы: ${transfers.length}',
  );
  stdout.writeln('--- август, профиль «Личный» (для бюджетов) ---');
  stdout.writeln(
    'Продукты:   ${sum(expenses, (t) => aug(t) && t.cat == 1)} / 25000',
  );
  stdout.writeln(
    'Кафе:       ${sum(expenses, (t) => aug(t) && t.cat == 2)} / 8000',
  );
  stdout.writeln(
    'Развл.+одежда: '
    '${sum(expenses, (t) => aug(t) && (t.cat == 6 || t.cat == 7))} / 15000',
  );
  stdout.writeln('Все расходы: ${sum(expenses, aug)} / 110000');
  stdout.writeln('Доходы за август: ${sum(incomes, (t) => aug(t))}');

  stdout.writeln('--- итоговые балансы счетов ---');
  for (final a in accounts) {
    var bal = a.initial;
    for (final t in incomes) {
      if (t.acc == a.id) bal += t.amount;
    }
    for (final t in expenses) {
      if (t.acc == a.id) bal -= t.amount;
    }
    for (final t in transfers) {
      if (t.from == a.id) bal -= t.amount;
      if (t.to == a.id) bal += t.amount;
    }
    final flag = bal < 0 ? '  <-- МИНУС' : '';
    stdout.writeln(
      '  ${a.name.padRight(18)} '
      '${bal.toStringAsFixed(0).padLeft(9)}$flag',
    );
  }
}
