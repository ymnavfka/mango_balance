import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';
import 'package:mango_balance/features/statistics/domain/entities/category_averages.dart';
import 'package:mango_balance/features/statistics/domain/entities/period_range.dart';
import 'package:mango_balance/features/statistics/domain/entities/period_type.dart';
import 'package:mango_balance/features/statistics/presentation/utils/category_comparison_labels.dart';
import 'package:mango_balance/features/statistics/presentation/widgets/category_comparison_header.dart';

CategoryAverages averages({int count = 21, bool partial = false, int? days}) =>
    CategoryAverages(
      periodCount: count,
      historyStart: count == 0 ? null : DateTime(2025, 1),
      historyEnd: count == 0 ? null : DateTime(2026, 10),
      matchesElapsedDays: partial,
      elapsedDays: days,
      incomeBreakdown: const [],
      expenseBreakdown: const [],
      totalIncome: 0,
      totalExpense: 0,
    );

Future<void> mountHeader(WidgetTester tester, CategoryAverages value) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryComparisonHeader(
            periodType: PeriodType.month,
            averages: value,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('partial period label describes only the elapsed days', () {
    final range = PeriodRange(
      start: DateTime(2026, 10),
      end: DateTime(2026, 11),
      label: 'окт 2026',
    );
    expect(categoryPeriodLabel(PeriodType.month, range), 'Октябрь');
    expect(
      categoryPeriodLabel(
        PeriodType.month,
        range,
        matchesElapsedDays: true,
        elapsedDays: 7,
      ),
      '1–7 окт.',
    );
    expect(
      categoryAverageLabel(PeriodType.month, matchesElapsedDays: true),
      'Среднее за эти дни',
    );
  });

  test('week label preserves both years across New Year', () {
    expect(
      categoryPeriodLabel(
        PeriodType.week,
        PeriodRange(
          start: DateTime(2025, 12, 29),
          end: DateTime(2026, 1, 5),
          label: '',
        ),
      ),
      '29 дек. 2025 — 4 янв. 2026',
    );
  });

  test('history range uses the last included day, not the exclusive end', () {
    expect(
      comparisonHistoryLabel(
        PeriodType.month,
        DateTime(2025, 1),
        DateTime(2026, 10),
      ),
      'янв. 2025 — сент. 2026',
    );
    expect(
      comparisonHistoryLabel(
        PeriodType.day,
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 8),
      ),
      '7 окт. 2026',
    );
  });

  test('period count has correct Russian forms for teens and 21', () {
    expect(comparisonPeriodCountLabel(PeriodType.month, 1), '1 полный месяц');
    expect(comparisonPeriodCountLabel(PeriodType.month, 2), '2 полных месяца');
    expect(
      comparisonPeriodCountLabel(PeriodType.month, 11),
      '11 полных месяцев',
    );
    expect(comparisonPeriodCountLabel(PeriodType.month, 21), '21 полный месяц');
    expect(comparisonPeriodCountLabel(PeriodType.week, 1), '1 полная неделя');
    expect(comparisonPeriodCountLabel(PeriodType.week, 2), '2 полные недели');
    expect(comparisonPeriodCountLabel(PeriodType.year, 5), '5 полных лет');
  });

  testWidgets('method is keyboard accessible and fits narrow large text', (
    tester,
  ) async {
    await mountHeader(tester, averages(partial: true, days: 7));
    expect(find.text('Сравнение за те же дни'), findsOneWidget);
    expect(
      find.text('янв. 2025 — сент. 2026 · 21 полный месяц'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(IconButton)).shortestSide,
      greaterThanOrEqualTo(48),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('с первыми 7 днями каждого завершённого месяца'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Периоды без операций тоже учитываем.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Периоды без операций тоже учитываем.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('insufficient history is explained without a fake zero average', (
    tester,
  ) async {
    await mountHeader(tester, averages(count: 0));
    expect(
      find.text('Для среднего нужен хотя бы один полный период истории.'),
      findsOneWidget,
    );
    expect(find.textContaining('0 полных'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
