import 'dart:math' as math;

/// Amounts are integer kopecks so distribution never creates extra money.
class GoalPlan {
  const GoalPlan({
    required this.id,
    required this.profileId,
    required this.name,
    required this.target,
    required this.dueDate,
    required this.anchorDate,
    this.intervalUnit,
    this.intervalCount = 1,
    this.accountId,
    this.manualSaved = 0,
    this.status = 'active',
    this.savedSnapshot = 0,
    this.sourcePaymentId,
  });
  final int id, profileId, target, intervalCount, manualSaved, savedSnapshot;
  final String name, status;
  final DateTime dueDate, anchorDate;
  final String? intervalUnit;
  final int? accountId, sourcePaymentId;
  bool get isActive => status == 'active';
}

DateTime goalDay(DateTime date) => DateTime(date.year, date.month, date.day);
int calendarDays(DateTime start, DateTime end) => DateTime.utc(
  end.year,
  end.month,
  end.day,
).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

/// Equal capped shares; leftover kopecks use stable id order.
Map<int, int> allocateGoals(List<GoalPlan> goals, Map<int, int> balances) {
  final result = <int, int>{};
  final groups = <int, List<GoalPlan>>{};
  for (final goal in goals) {
    if (!goal.isActive) continue;
    if (goal.accountId == null) {
      result[goal.id] = goal.manualSaved.clamp(0, goal.target);
    } else {
      groups.putIfAbsent(goal.accountId!, () => []).add(goal);
    }
  }
  for (final entry in groups.entries) {
    final pending = [...entry.value]
      ..sort((a, b) {
        final comparison = a.target.compareTo(b.target);
        return comparison == 0 ? a.id.compareTo(b.id) : comparison;
      });
    var money = math.max(0, balances[entry.key] ?? 0);
    while (pending.isNotEmpty) {
      final share = money ~/ pending.length;
      if (pending.first.target <= share) {
        final goal = pending.removeAt(0);
        result[goal.id] = goal.target;
        money -= goal.target;
      } else {
        pending.sort((a, b) => a.id.compareTo(b.id));
        final remainder = money % pending.length;
        for (var i = 0; i < pending.length; i++) {
          result[pending[i].id] = share + (i < remainder ? 1 : 0);
        }
        break;
      }
    }
  }
  return result;
}

/// Uses the original anchor, so Jan 31 -> Feb 28 -> Mar 31, not Mar 28.
DateTime goalOccurrence(GoalPlan goal, int index) {
  final anchor = goal.anchorDate;
  final count = goal.intervalCount * index;
  if (goal.intervalUnit == 'day' || goal.intervalUnit == 'week') {
    return DateTime(
      anchor.year,
      anchor.month,
      anchor.day + count * (goal.intervalUnit == 'week' ? 7 : 1),
    );
  }
  final months = count * (goal.intervalUnit == 'year' ? 12 : 1);
  final month = DateTime(anchor.year, anchor.month + months);
  return DateTime(
    month.year,
    month.month,
    math.min(anchor.day, DateTime(month.year, month.month + 1, 0).day),
  );
}

DateTime nextGoalDeadline(GoalPlan goal, DateTime today) {
  var index = 0;
  final days = calendarDays(goal.anchorDate, today);
  if (goal.intervalUnit == 'day' || goal.intervalUnit == 'week') {
    final period = goal.intervalCount * (goal.intervalUnit == 'week' ? 7 : 1);
    index = math.max(0, (days / period).ceil());
  } else {
    final months =
        (today.year - goal.anchorDate.year) * 12 +
        today.month -
        goal.anchorDate.month;
    index = math.max(
      0,
      months ~/ (goal.intervalCount * (goal.intervalUnit == 'year' ? 12 : 1)),
    );
  }
  var date = goalOccurrence(goal, index);
  while (date.isBefore(goalDay(today))) {
    date = goalOccurrence(goal, ++index);
  }
  return date;
}

/// Deadline remains usable throughout its calendar day.
double dailyGoalRate(GoalPlan goal, int saved, DateTime now) {
  if (!goal.isActive) return 0;
  final remaining = math.max(0, goal.target - saved);
  return remaining / math.max(1, calendarDays(now, goal.dueDate));
}
