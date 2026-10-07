import 'dart:ui' show PointerDeviceKind;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';
import 'package:mango_balance/features/shared/utils/money_format.dart';
import 'package:mango_balance/features/statistics/domain/entities/category_breakdown.dart';
import 'package:mango_balance/features/statistics/presentation/widgets/category_donut_chart.dart';

List<CategoryBreakdown> breakdown({bool average = false}) => [
  CategoryBreakdown(
    categoryId: 1,
    categoryName: 'Продукты',
    amount: average ? 3000 : 6000,
    share: average ? .3 : .6,
  ),
  CategoryBreakdown(
    categoryId: 2,
    categoryName: 'Транспорт',
    amount: average ? 7000 : 4000,
    share: average ? .7 : .4,
  ),
];

CategoryDonutChart comparison({bool reducedHistory = false}) =>
    CategoryDonutChart(
      title: 'Расходы по категориям',
      total: 10000,
      breakdown: breakdown(),
      accentColor: Colors.red,
      icon: Icons.north_east,
      showComparison: true,
      averageTotal: reducedHistory ? null : 10000,
      averageBreakdown: reducedHistory ? const [] : breakdown(average: true),
      periodLabel: 'Октябрь',
      averageLabel: 'В среднем за месяц',
    );

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 873),
  double scale = 1,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

List<PieChart> charts(WidgetTester tester) =>
    tester.widgetList<PieChart>(find.byType(PieChart)).toList();

Future<void> tapText(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('comparison renders both distributions with matching colors', (
    tester,
  ) async {
    await mount(tester, comparison());

    expect(find.byType(PieChart), findsNWidgets(2));
    expect(find.text('Октябрь'), findsWidgets);
    expect(find.text('В среднем за месяц'), findsWidgets);
    final pair = charts(tester);
    expect(pair[0].data.sections.map((section) => section.value), [6000, 4000]);
    expect(pair[1].data.sections.map((section) => section.value), [3000, 7000]);
    expect(
      pair[0].data.sections.map((section) => section.color),
      pair[1].data.sections.map((section) => section.color),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('legend selection highlights the same category on both charts', (
    tester,
  ) async {
    await mount(tester, comparison());
    final originalColors = charts(
      tester,
    ).first.data.sections.map((section) => section.color).toList();

    await tapText(tester, 'Продукты');

    for (final chart in charts(tester)) {
      expect(chart.data.sections.first.color, originalColors.first);
      expect(chart.data.sections.last.color.a, lessThan(originalColors.last.a));
    }

    await tapText(tester, 'Продукты');

    for (final chart in charts(tester)) {
      expect(
        chart.data.sections.map((section) => section.color),
        originalColors,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecting a historical chart segment also updates the current chart',
    (tester) async {
      await mount(tester, comparison());
      final historicalChart = charts(tester).last;
      final section = historicalChart.data.sections.last;
      historicalChart.data.pieTouchData.touchCallback!(
        FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
        PieTouchResponse(PieTouchedSection(section, 1, 90, 60)),
      );
      await tester.pumpAndSettle();

      for (final chart in charts(tester)) {
        expect(chart.data.sections.last.color, section.color);
        expect(
          chart.data.sections.first.color.a,
          lessThan(chart.data.sections.last.color.a),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('amount mode exposes exact category amounts for both periods', (
    tester,
  ) async {
    await mount(tester, comparison());

    expect(find.text('Доли'), findsOneWidget);
    expect(find.text('Суммы'), findsOneWidget);
    await tapText(tester, 'Суммы');

    expect(find.text(formatMoneyAbs(6000)), findsWidgets);
    expect(find.text(formatMoneyAbs(3000)), findsWidgets);
    expect(find.byType(PieChart), findsNWidgets(2));

    await tapText(tester, 'Доли');

    expect(find.byType(PieChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a period without operations retains the historical distribution',
    (tester) async {
      await mount(
        tester,
        CategoryDonutChart(
          title: 'Расходы по категориям',
          total: 0,
          breakdown: const [],
          accentColor: Colors.red,
          icon: Icons.north_east,
          showComparison: true,
          averageTotal: 10000,
          averageBreakdown: breakdown(average: true),
        ),
      );

      expect(find.text('Нет операций'), findsOneWidget);
      expect(find.byTooltip(formatMoneyAbs(10000)), findsWidgets);
      expect(
        charts(tester).last.data.sections.map((section) => section.value),
        [3000, 7000],
      );
      expect(find.text('Продукты'), findsWidgets);
      expect(find.text('Транспорт'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('insufficient history is not displayed as a zero average', (
    tester,
  ) async {
    await mount(tester, comparison(reducedHistory: true));

    expect(find.text('Пока нет среднего'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text(formatMoneyAbs(0)), findsNothing);
    expect(find.textContaining('100%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a known zero average does not become unavailable history', (
    tester,
  ) async {
    await mount(
      tester,
      CategoryDonutChart(
        title: 'Расходы по категориям',
        total: 10000,
        breakdown: breakdown(),
        accentColor: Colors.red,
        icon: Icons.north_east,
        showComparison: true,
        averageTotal: 0,
        averageBreakdown: const [],
      ),
    );

    expect(find.text('Пока нет среднего'), findsNothing);
    expect(find.text('Нет операций'), findsOneWidget);
    expect(find.textContaining('Infinity'), findsNothing);
    expect(find.textContaining('NaN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all-time view keeps a single chart without comparison controls',
    (tester) async {
      await mount(
        tester,
        CategoryDonutChart(
          title: 'Расходы по категориям',
          total: 10000,
          breakdown: breakdown(),
          accentColor: Colors.red,
          icon: Icons.north_east,
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('В среднем'), findsNothing);
      expect(find.text('Суммы'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('other category expands its shared category details', (
    tester,
  ) async {
    List<CategoryBreakdown> withOther({required double amount}) => [
      CategoryBreakdown(
        categoryId: null,
        categoryName: 'Другое',
        amount: amount,
        share: 1,
        children: [
          CategoryBreakdown(
            categoryId: 3,
            categoryName: 'Подписки',
            amount: amount,
            share: 1,
          ),
        ],
      ),
    ];
    await mount(
      tester,
      CategoryDonutChart(
        title: 'Расходы по категориям',
        total: 500,
        breakdown: withOther(amount: 500),
        accentColor: Colors.red,
        icon: Icons.north_east,
        showComparison: true,
        averageTotal: 300,
        averageBreakdown: withOther(amount: 300),
      ),
    );

    expect(find.text('Подписки'), findsNothing);
    await tapText(tester, 'Другое');
    expect(find.text('Подписки'), findsOneWidget);
    await tapText(tester, 'Другое');
    expect(find.text('Подписки'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables animation for both distributions', (
    tester,
  ) async {
    await mount(tester, comparison(), reducedMotion: true);

    expect(charts(tester), hasLength(2));
    for (final chart in charts(tester)) {
      expect(chart.duration, Duration.zero);
    }
    await tapText(tester, 'Транспорт');
    for (final chart in charts(tester)) {
      expect(chart.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('comparison fits large values at 320px and text scale $scale', (
      tester,
    ) async {
      List<CategoryBreakdown> largeBreakdown(double amount) => [
        CategoryBreakdown(
          categoryId: 1,
          categoryName: 'Очень длинная категория расходов',
          amount: amount,
          share: 1,
        ),
      ];
      await mount(
        tester,
        CategoryDonutChart(
          title: 'Расходы по категориям',
          total: 1234567890.12,
          breakdown: largeBreakdown(1234567890.12),
          accentColor: Colors.red,
          icon: Icons.north_east,
          showComparison: true,
          averageTotal: 987654321.99,
          averageBreakdown: largeBreakdown(987654321.99),
          periodLabel: 'Выбранный промежуток времени',
          averageLabel: 'В среднем за такой же период',
          matchesElapsedDays: true,
        ),
        size: const Size(320, 568),
        scale: scale,
      );

      expect(tester.takeException(), isNull);
      await tapText(tester, 'Суммы');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Очень длинная категория расходов');
      expect(tester.takeException(), isNull);
      expect(find.byType(PieChart), findsNWidgets(2));
    });
  }
}
