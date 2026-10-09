import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/features/accounts/domain/entities/account.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_cubit.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_state.dart';
import 'package:mango_balance/features/categories/domain/entities/category.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_cubit.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_state.dart';
import 'package:mango_balance/features/shared/widgets/app_dropdown_field.dart';
import 'package:mango_balance/features/transactions/domain/entities/transaction.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/amount.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/transaction_date.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:mango_balance/features/transactions/presentation/widgets/transaction_form_dialog.dart';

class Accounts extends Cubit<AccountState> implements AccountCubit {
  Accounts()
    : super(
        AccountState.initial().copyWith(
          accounts: const [
            AccountEntity(id: 1, name: 'Active account', isFallback: true),
            AccountEntity(
              id: 2,
              name: 'Archived account',
              isFallback: false,
              isArchived: true,
            ),
            AccountEntity(
              id: 3,
              name: 'Other archived account',
              isFallback: false,
              isArchived: true,
            ),
          ],
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Categories extends Cubit<CategoryState> implements CategoryCubit {
  Categories()
    : super(
        CategoryState(
          categories: const [
            CategoryEntity(
              id: 1,
              name: 'Active category',
              type: TransactionType.expense,
              isFallback: true,
            ),
            CategoryEntity(
              id: 2,
              name: 'Archived category',
              type: TransactionType.expense,
              isFallback: false,
              isArchived: true,
            ),
            CategoryEntity(
              id: 3,
              name: 'Other archived category',
              type: TransactionType.expense,
              isFallback: false,
              isArchived: true,
            ),
          ],
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Transactions extends Cubit<TransactionState> implements TransactionCubit {
  Transactions() : super(TransactionState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final editing in [false, true]) {
    testWidgets(
      editing
          ? 'editing history keeps its archived references'
          : 'new transaction excludes archived choices',
      (tester) async {
        final accounts = Accounts();
        final categories = Categories();
        final transactions = Transactions();
        addTearDown(accounts.close);
        addTearDown(categories.close);
        addTearDown(transactions.close);
        final initial = editing
            ? TransactionEntity(
                id: 1,
                type: TransactionType.expense,
                amount: Amount(100),
                date: TransactionDate(DateTime(2026)),
                categoryId: 2,
                categoryName: 'Archived category',
                accountId: 2,
                accountName: 'Archived account',
                toAccountId: 2,
                toAccountName: 'Archived account',
                comment: null,
              )
            : null;
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AccountCubit>.value(value: accounts),
              BlocProvider<CategoryCubit>.value(value: categories),
              BlocProvider<TransactionCubit>.value(value: transactions),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: TransactionFormDialog(initial: initial, onSubmit: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = tester.widgetList<AppDropdownField<int>>(
          find.byType(AppDropdownField<int>),
        );
        expect(fields, isNotEmpty);
        for (final field in fields) {
          expect(
            field.items.map((item) => item.value),
            unorderedEquals(editing ? [1, 2] : [1]),
          );
          expect(field.value, editing ? 2 : 1);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
