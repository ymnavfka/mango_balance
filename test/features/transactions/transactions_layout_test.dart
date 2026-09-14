import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/features/accounts/domain/entities/account.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_cubit.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_state.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';
import 'package:mango_balance/features/transactions/domain/entities/transaction.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/amount.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/transaction_date.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:mango_balance/features/transactions/presentation/pages/transactions_page.dart';

class TestTransactions extends Cubit<TransactionState>
    implements TransactionCubit {
  TestTransactions(super.initialState);

  @override
  void selectAccount(int? accountId) =>
      emit(state.copyWith(selectedAccountId: accountId, selectedBalance: 1234));

  @override
  Future<void> toggleTransactionType(TransactionType type) async {
    final types = {...state.visibleTypes};
    if (!types.remove(type)) types.add(type);
    emit(state.copyWith(visibleTypes: types));
  }

  @override
  Future<void> resetFilters() async => emit(
    state.copyWith(
      visibleTypes: TransactionType.values.toSet(),
      dateRange: null,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAccounts extends Cubit<AccountState> implements AccountCubit {
  TestAccounts()
    : super(
        AccountState.initial().copyWith(
          accounts: [
            const AccountEntity(
              id: 1,
              name: 'Основная карта',
              isFallback: false,
            ),
            const AccountEntity(id: 2, name: 'Накопления', isFallback: false),
          ],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionState fixture() {
  final transactions = List.generate(
    14,
    (i) => TransactionEntity(
      id: i + 1,
      type: i % 7 == 2
          ? TransactionType.income
          : i % 7 == 5
          ? TransactionType.transfer
          : TransactionType.expense,
      amount: Amount(
        [1840.0, 290.0, 85000.0, 620.0, 499.0, 10000.0, 3250.0][i % 7],
      ),
      date: TransactionDate(DateTime(2026, 1, 1, 12, 34)),
      categoryId: 1,
      categoryName: [
        'Продукты',
        'Кофе',
        'Зарплата',
        'Транспорт',
        'Подписки',
        'Перевод',
        'Покупки',
      ][i % 7],
      accountId: 1,
      accountName: 'Основная карта',
      toAccountId: i % 7 == 5 ? 2 : null,
      toAccountName: i % 7 == 5 ? 'Накопления' : null,
      comment: 'Комментарий к покупке',
    ),
  );
  return TransactionState.initial().copyWith(
    transactions: transactions,
    allTransactions: transactions,
    selectedBalance: 124580.50,
    sections: [
      TransactionSection(
        title: 'Сегодня',
        transactions: transactions.take(3).toList(),
      ),
      TransactionSection(
        title: 'Вчера',
        transactions: transactions.skip(3).toList(),
      ),
    ],
  );
}

Future<TestTransactions> showPage(
  WidgetTester tester, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final transactions = TestTransactions(fixture());
  final accounts = TestAccounts();
  addTearDown(transactions.close);
  addTearDown(accounts.close);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<TransactionCubit>.value(value: transactions),
        BlocProvider<AccountCubit>.value(value: accounts),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const TransactionsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return transactions;
}

void main() {
  testWidgets('360×740 screen fits four full transactions above the add button', (
    tester,
  ) async {
    await showPage(tester);
    tester.view.physicalSize = const Size(360, 740);
    await tester.pumpAndSettle();
    expect(find.text('Комментарий к покупке'), findsNothing);
    expect(find.text('12:34'), findsNothing);
    expect(find.text('Доход'), findsNothing);
    expect(find.text('За всё время'), findsNothing);
    final fourth = find.byKey(const ValueKey(4));
    final add = find.byType(FloatingActionButton);
    expect(
      tester.getBottomLeft(fourth).dy,
      lessThan(tester.getTopLeft(add).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('accounts remain accessible and filters open, update and reset', (
    tester,
  ) async {
    final cubit = await showPage(tester);
    await tester.tap(find.text('Основная карта').first);
    await tester.pumpAndSettle();
    expect(cubit.state.selectedAccountId, 1);
    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    expect(find.text('За всё время'), findsOneWidget);
    await tester.tap(find.text('Доход'));
    await tester.pumpAndSettle();
    expect(cubit.state.visibleTypes, isNot(contains(TransactionType.income)));
    expect(find.byTooltip('Фильтры: активно 1'), findsOneWidget);
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(cubit.state.visibleTypes.length, 3);
    expect(cubit.state.selectedAccountId, 1);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Доход'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text fits the small screen and filter sheet', (
    tester,
  ) async {
    await showPage(tester, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
