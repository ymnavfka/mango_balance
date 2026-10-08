import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';
import 'package:mango_balance/features/shared/utils/money_format.dart';
import 'package:mango_balance/features/statistics/domain/entities/net_worth_point.dart';
import 'package:mango_balance/features/statistics/presentation/widgets/net_worth_line_chart.dart';

final points = [
  NetWorthPoint(date: DateTime(2026, 8, 31), balance: 100),
  NetWorthPoint(date: DateTime(2026, 9, 1), balance: 125.25),
  NetWorthPoint(date: DateTime(2026, 9, 16), balance: 200),
  NetWorthPoint(date: DateTime(2026, 9, 30), balance: 190),
];

Future<void> mount(
  WidgetTester tester, {
  Size size = const Size(393, 900),
  double scale = 1,
  List<NetWorthPoint>? series,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: NetWorthLineChart(points: series ?? points),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String read(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  testWidgets(
    'period delta includes the first visible day and controls change the range',
    (tester) async {
      await mount(tester);
      expect(read(tester, 'net-worth-balance'), formatMoney(190));
      expect(read(tester, 'net-worth-change'), '+${formatMoney(90)} за период');
      await tap(tester, find.text('7 д'));
      expect(read(tester, 'net-worth-change'), '${formatMoney(-10)} за период');
      expect(find.text('24 сентября 2026 — 30 сентября 2026'), findsOneWidget);
      await tap(tester, find.text('Всё'));
      expect(find.text('31 августа 2026 — 30 сентября 2026'), findsOneWidget);
    },
  );

  testWidgets('whole plot selects days without operations and pins the value', (
    tester,
  ) async {
    await mount(tester);
    final rect = tester.getRect(find.byKey(const ValueKey('net-worth-plot')));
    // September 10, well away from the actual line and recorded operations.
    await tester.tapAt(
      Offset(rect.left + 8 + (rect.width - 80) * 9 / 29, rect.top + 15),
    );
    await tester.pumpAndSettle();
    expect(read(tester, 'net-worth-balance'), formatMoney(125.25));
    expect(find.text('10 сентября 2026 · на конец дня'), findsOneWidget);
    await tap(tester, find.text('К последнему дню'));
    expect(read(tester, 'net-worth-balance'), formatMoney(190));
  });

  testWidgets('hover previews exact day and returns to the latest balance', (
    tester,
  ) async {
    await mount(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final rect = tester.getRect(find.byKey(const ValueKey('net-worth-plot')));
    await mouse.moveTo(Offset(rect.left + 8, rect.top + 20));
    await tester.pumpAndSettle();
    expect(read(tester, 'net-worth-balance'), formatMoney(125.25));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(read(tester, 'net-worth-balance'), formatMoney(190));
    await mouse.removePointer();
  });

  testWidgets(
    'detail navigation and calendar show closing and opening balances',
    (tester) async {
      await mount(tester);
      await tap(tester, find.text('Точный просмотр'));
      expect(read(tester, 'net-worth-change'), '${formatMoney(-10)} за день');
      await tap(tester, find.byTooltip('Предыдущий день'));
      expect(read(tester, 'net-worth-balance'), formatMoney(200));
      expect(read(tester, 'net-worth-change'), '${formatMoney(0)} за день');
      expect(find.text('Без изменений'), findsOneWidget);
      await tap(tester, find.text('29 сентября 2026'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('16').last);
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      expect(
        read(tester, 'net-worth-change'),
        '+${formatMoney(74.75)} за день',
      );
      await tap(tester, find.text('7 д'));
      expect(find.text('24 сентября 2026 · на конец дня'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('phone and enlarged text fit in overview and detail', (
    tester,
  ) async {
    await mount(
      tester,
      size: const Size(320, 900),
      scale: 1.8,
      series: [
        NetWorthPoint(date: DateTime(2026, 9, 1), balance: -123456789.12),
        NetWorthPoint(date: DateTime(2026, 9, 30), balance: -123456789.12),
      ],
    );
    expect(tester.takeException(), isNull);
    await tap(tester, find.text('Точный просмотр'));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('На конец дня'), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single point and zero balance render without invalid geometry', (
    tester,
  ) async {
    await mount(
      tester,
      series: [NetWorthPoint(date: DateTime(2026, 9, 1), balance: 0)],
    );
    expect(read(tester, 'net-worth-balance'), formatMoney(0));
    expect(tester.takeException(), isNull);
  });
}
