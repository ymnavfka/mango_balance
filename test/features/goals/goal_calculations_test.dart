import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/goals/domain/goal.dart';

GoalPlan plan(
  int id,
  int amount, {
  int? account = 1,
  String? unit,
  DateTime? due,
  int manual = 0,
  String status = 'active',
  int count = 1,
}) => GoalPlan(
  id: id,
  profileId: 1,
  name: 'Goal $id',
  target: amount,
  dueDate: due ?? DateTime(2026, 10, 15),
  anchorDate: due ?? DateTime(2026, 10, 15),
  accountId: account,
  manualSaved: manual,
  status: status,
  intervalUnit: unit,
  intervalCount: count,
);
void main() {
  test('small targets release excess to the remaining goals', () {
    expect(
      allocateGoals(
        [plan(1, 1000000), plan(2, 5000000), plan(3, 10000000)],
        {1: 9000000},
      ),
      {1: 1000000, 2: 4000000, 3: 4000000},
    );
  });
  test(
    'rounding conserves kopecks, order is stable and surplus stays free',
    () {
      final goals = [plan(2, 100), plan(1, 100), plan(3, 100)];
      expect(allocateGoals(goals, {1: 101}), {1: 34, 2: 34, 3: 33});
      expect(allocateGoals(goals, {1: 999}), {1: 100, 2: 100, 3: 100});
      expect(allocateGoals(goals, {1: -100}), {1: 0, 2: 0, 3: 0});
    },
  );
  test(
    'manual savings and inactive goals cannot double count account funds',
    () {
      expect(
        allocateGoals(
          [
            plan(1, 100),
            plan(2, 100, status: 'paused'),
            plan(3, 100, status: 'completed'),
            plan(4, 100, account: null, manual: 200),
          ],
          {1: 80},
        ),
        {1: 80, 4: 100},
      );
    },
  );
  test('monthly repeats preserve anchor and skip missed cycles', () {
    final goal = plan(1, 100, unit: 'month', due: DateTime(2026, 1, 31));
    expect(nextGoalDeadline(goal, DateTime(2026, 2, 1)), DateTime(2026, 2, 28));
    expect(nextGoalDeadline(goal, DateTime(2026, 3, 1)), DateTime(2026, 3, 31));
    expect(nextGoalDeadline(goal, DateTime(2030, 4, 1)), DateTime(2030, 4, 30));
  });
  test('yearly repeats preserve leap day; every N weeks retains cadence', () {
    final leap = plan(1, 100, unit: 'year', due: DateTime(2024, 2, 29));
    expect(nextGoalDeadline(leap, DateTime(2025, 1, 1)), DateTime(2025, 2, 28));
    expect(nextGoalDeadline(leap, DateTime(2028, 1, 1)), DateTime(2028, 2, 29));
    expect(
      nextGoalDeadline(
        plan(1, 100, unit: 'week', count: 2, due: DateTime(2026, 1, 1)),
        DateTime(2026, 1, 2),
      ),
      DateTime(2026, 1, 15),
    );
  });
  test(
    'rates are finite at deadline and zero for inactive or filled goals',
    () {
      final goal = plan(1, 6000000, due: DateTime(2026, 5, 1));
      expect(dailyGoalRate(goal, 1200000, DateTime(2026, 1, 1)), 40000);
      expect(dailyGoalRate(goal, 0, DateTime(2026, 5, 1, 23)), 6000000);
      expect(dailyGoalRate(goal, 6000000, DateTime(2026, 4, 1)), 0);
      expect(
        dailyGoalRate(plan(2, 100, status: 'paused'), 0, DateTime(2026)),
        0,
      );
    },
  );
}
