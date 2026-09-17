import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mango_balance/features/categories/domain/entities/category.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_cubit.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_state.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_cubit.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_state.dart';
import 'package:mango_balance/features/recurring/presentation/pages/recurring_payments_page.dart';
import 'package:mango_balance/features/recurring/presentation/widgets/recurring_payment_form_dialog.dart';
import 'package:mango_balance/features/transactions/presentation/widgets/transaction_form_dialog.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import '../recurring/notification_flow_test.dart' as recurring;
import '../recurring/notification_widgets_test.dart' as notifications;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mango_balance/features/budgets/domain/entities/budget.dart';
import 'package:mango_balance/features/budgets/domain/entities/budget_period.dart';
import 'package:mango_balance/features/budgets/domain/entities/budget_progress.dart';
import 'package:mango_balance/features/budgets/presentation/widgets/budget_progress_card.dart';
import 'package:mango_balance/features/shared/widgets/app_drawer.dart';
import 'package:mango_balance/features/profiles/presentation/cubit/profile_cubit.dart';
import 'package:mango_balance/features/profiles/presentation/cubit/profile_state.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_cubit.dart';
import 'package:mango_balance/features/accounts/presentation/pages/accounts_page.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_cubit.dart';
import '../transactions/transactions_layout_test.dart' as transactions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';
import 'package:mango_balance/features/shared/widgets/app_dialog.dart';
import 'package:mango_balance/features/shared/widgets/calculator_sheet.dart';
import 'package:mango_balance/features/shared/widgets/empty_state.dart';
import 'package:mango_balance/features/shared/widgets/undo_snackbar.dart';
import 'package:mango_balance/features/statistics/domain/entities/category_breakdown.dart';
import 'package:mango_balance/features/statistics/presentation/widgets/category_donut_chart.dart';

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(320, 568),
  double scale = 2,
  double keyboard = 0,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ru'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ru')],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

class TestProfiles extends Cubit<ProfileState> implements ProfileCubit {
  TestProfiles() : super(ProfileState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCategories extends Cubit<CategoryState> implements CategoryCubit {
  TestCategories()
    : super(
        CategoryState(
          categories: [
            const CategoryEntity(
              id: 1,
              name: 'Продукты',
              type: TransactionType.expense,
              isFallback: false,
            ),
          ],
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestRecurring extends notifications.SettingsCubit {
  bool? active;
  @override
  Future<void> setActive(int id, bool value) async {
    active = value;
  }

  @override
  RecurringState get state => RecurringState(payments: [recurring.payment()]);
}

void main() {
  for (final recurringForm in [false, true]) {
    testWidgets(
      'real form fits narrow screen with keyboard, recurring=$recurringForm',
      (tester) async {
        final categories = TestCategories();
        final accounts = transactions.TestAccounts();
        final txs = transactions.TestTransactions(transactions.fixture());
        addTearDown(categories.close);
        addTearDown(accounts.close);
        addTearDown(txs.close);
        await mount(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider<CategoryCubit>.value(value: categories),
              BlocProvider<AccountCubit>.value(value: accounts),
              BlocProvider<TransactionCubit>.value(value: txs),
              BlocProvider<RecurringCubit>.value(value: TestRecurring()),
            ],
            child: recurringForm
                ? RecurringPaymentFormDialog(
                    initial: recurring.payment(),
                    onSubmit: (_) async {},
                  )
                : TransactionFormDialog(
                    initial: transactions.fixture().transactions.first,
                    onSubmit: (_) {},
                  ),
          ),
          keyboard: 220,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Сохранить'));
        await tester.pumpAndSettle();
        expect(find.text('Сохранить').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('recurring payments stay reachable below summary in landscape', (
    tester,
  ) async {
    final cubit = TestRecurring();
    await mount(
      tester,
      BlocProvider<RecurringCubit>.value(
        value: cubit,
        child: const RecurringPaymentsPage(),
      ),
      size: const Size(640, 320),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byType(Switch),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    expect(cubit.active, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'drawer labels and last destination fit landscape with large text',
    (tester) async {
      final profiles = TestProfiles();
      addTearDown(profiles.close);
      await mount(
        tester,
        BlocProvider<ProfileCubit>.value(
          value: profiles,
          child: const AppDrawer(currentRoute: AppRoute.transactions),
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Профили'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Профили').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account balances fit large text and long amounts', (
    tester,
  ) async {
    final accounts = transactions.TestAccounts();
    accounts.emit(
      accounts.state.copyWith(
        balances: {1: 1234567890.12},
        totalBalance: 1234567890.12,
      ),
    );
    final txs = transactions.TestTransactions(transactions.fixture());
    addTearDown(accounts.close);
    addTearDown(txs.close);
    await mount(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountCubit>.value(value: accounts),
          BlocProvider<TransactionCubit>.value(value: txs),
        ],
        child: const AccountsPage(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget values and remaining amount fit large text', (
    tester,
  ) async {
    await mount(
      tester,
      SingleChildScrollView(
        child: BudgetProgressCard(
          progress: BudgetProgress(
            budget: const BudgetEntity(
              id: 1,
              name: 'Бюджет на продукты',
              limitAmount: 1234567890,
              period: BudgetPeriod.month,
              allCategories: true,
              categoryIds: [],
            ),
            spent: 987654321,
            periodStart: DateTime(2026, 9),
            periodEnd: DateTime(2026, 10),
            daysRemaining: 10,
            categoryNames: [],
          ),
          onTap: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait calculator keeps its original height', (tester) async {
    const size = Size(393, 873);
    await mount(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: CalculatorSheet(initialValue: 125, onChanged: (_) {}),
      ),
      size: size,
      scale: 1,
    );
    expect(
      tester.getSize(find.byType(CalculatorSheet)).height,
      closeTo(size.height * .62, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog actions and last field remain reachable with keyboard', (
    tester,
  ) async {
    var saved = false;
    await mount(
      tester,
      AppDialog(
        title: 'Редактировать регулярный платёж',
        primaryLabel: 'Сохранить изменения',
        onPrimary: () => saved = true,
        child: Column(
          children: List.generate(
            8,
            (i) => TextField(decoration: InputDecoration(labelText: 'Поле $i')),
          ),
        ),
      ),
      keyboard: 250,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Поле 7'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape calculator preserves usable keys and calculation', (
    tester,
  ) async {
    double? value;
    await mount(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => CalculatorSheet(
              initialValue: null,
              onChanged: (v) => value = v,
            ),
          ),
          child: const Text('Открыть'),
        ),
      ),
      size: const Size(740, 360),
      scale: 1,
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['7', '+', '2', '=']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      final key = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(key).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text(label));
    }
    expect(value, 9);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state scrolls on a short screen with large text', (
    tester,
  ) async {
    await mount(
      tester,
      const EmptyState(
        icon: Icons.event,
        title: 'Регулярных платежей пока нет',
        message:
            'Создайте платёж, и транзакции будут добавляться автоматически.',
      ),
      size: const Size(640, 280),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.text(
        'Создайте платёж, и транзакции будут добавляться автоматически.',
      ),
    );
  });

  testWidgets(
    'statistics fits large amounts and large text on a narrow screen',
    (tester) async {
      await mount(
        tester,
        SingleChildScrollView(
          child: CategoryDonutChart(
            title: 'Расходы по категориям',
            total: 1234567890.12,
            breakdown: [
              CategoryBreakdown(
                categoryId: 1,
                categoryName: 'Очень длинная категория расходов',
                amount: 1234567890.12,
                share: 1,
              ),
            ],
            accentColor: Colors.red,
            icon: Icons.north_east,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion undo stays available without animated countdown',
    (tester) async {
      var undone = false;
      await mount(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showUndoSnackBar(
              context,
              message: 'Операция удалена',
              onUndo: () => undone = true,
            ),
            child: const Text('Удалить'),
          ),
        ),
        scale: 1,
        reducedMotion: true,
      );
      await tester.tap(find.text('Удалить'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Отменить'), findsOneWidget);
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
    },
  );
}
