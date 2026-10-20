import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/services/active_profile_holder.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_cubit.dart';
import 'package:mango_balance/features/goals/domain/goal.dart';
import 'package:mango_balance/features/goals/presentation/goal_cubit.dart';
import 'package:mango_balance/features/goals/presentation/goal_form_dialog.dart';
import 'package:mango_balance/features/goals/presentation/goals_page.dart';
import 'package:mango_balance/features/goals/presentation/goal_payment_action.dart';
import '../archive/archive_form_test.dart' as fixtures;
import '../shared/adaptive_layout_test.dart' show mount;
import '../recurring/notification_flow_test.dart' as recurring;

class TestGoals extends Cubit<GoalSnapshot> implements GoalCubit {
  TestGoals(super.initialState);
  GoalPlan? saved;
  @override
  final profile = ActiveProfileHolder(initialId: 1);
  @override
  Future<void> save(GoalPlan goal) async {
    saved = goal;
  }

  @override
  Future<void> close() async {
    await profile.close();
    return super.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoalPlan fixture({String status = 'active', int? source}) => GoalPlan(
  id: 1,
  profileId: 1,
  name: 'Подарок на день рождения',
  target: 100000,
  dueDate: DateTime(2099, 10, 15),
  anchorDate: DateTime(2099, 10, 15),
  accountId: 2,
  status: status,
  savedSnapshot: 40000,
  sourcePaymentId: source,
);

void main() {
  testWidgets(
    'goals fit narrow screen and large text; paused progress is separate',
    (tester) async {
      final goals = TestGoals(
        GoalSnapshot(
          goals: [
            fixture(),
            GoalPlan(
              id: 2,
              profileId: 1,
              name: 'Приостановленная',
              target: 50000,
              dueDate: DateTime(2099),
              anchorDate: DateTime(2099),
              status: 'paused',
              savedSnapshot: 20000,
            ),
          ],
          allocations: const {1: 40000},
          balances: const {2: 40000},
          accountNames: const {2: 'Накопительный счёт'},
        ),
      );
      addTearDown(goals.close);
      await mount(
        tester,
        BlocProvider<GoalCubit>.value(value: goals, child: const GoalsPage()),
        size: const Size(320, 568),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Приостановленные'), 200);
      await tester.ensureVisible(find.text('Приостановленные'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Приостановленные'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Приостановленная'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Приостановленная'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('goal form fits keyboard and only offers active accounts', (
    tester,
  ) async {
    final accounts = fixtures.Accounts();
    addTearDown(accounts.close);
    await mount(
      tester,
      BlocProvider<AccountCubit>.value(
        value: accounts,
        child: const GoalFormDialog(),
      ),
      size: const Size(320, 568),
      scale: 2,
      keyboard: 220,
    );
    expect(tester.takeException(), isNull);
    final dropdown = tester.widget<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    // Inspecting menu choices through the underlying DropdownButton verifies
    // both archived accounts are excluded from new goal selection.
    expect(dropdown, isNotNull);
    final menu = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    expect(menu.items!.map((item) => item.value), [0, 1]);
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сохранить').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('payment action switches to open goal when a link exists', (
    tester,
  ) async {
    final payment = recurring.payment();
    final goals = TestGoals(const GoalSnapshot());
    addTearDown(goals.close);
    await mount(
      tester,
      BlocProvider<GoalCubit>.value(
        value: goals,
        child: GoalPaymentAction(payment: payment),
      ),
      scale: 1,
    );
    expect(find.text('Создать цель'), findsOneWidget);
    goals.emit(GoalSnapshot(goals: [fixture(source: payment.id)]));
    await tester.pumpAndSettle();
    expect(find.text('Открыть цель'), findsOneWidget);
    expect(find.text('Создать цель'), findsNothing);
  });
}
