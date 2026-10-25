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
    this.status = 'active',
    this.savedSnapshot = 0,
    this.savedOccurrenceCount = 0,
    this.savedThroughDate,
    this.sourcePaymentId,
  });
  final int id,
      profileId,
      target,
      intervalCount,
      savedSnapshot,
      savedOccurrenceCount;
  final String name, status;
  final DateTime dueDate, anchorDate;
  final DateTime? savedThroughDate;
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

class GoalCoverage {
  const GoalCoverage({
    this.allocated = 0,
    this.firstEventDate,
    this.firstEventAllocated = 0,
    this.coveredOccurrences = 0,
    this.coveredThrough,
    this.nextUncoveredDate,
    this.nextUncoveredAllocated = 0,
  });

  /// Total assigned across all upcoming occurrences of this goal.
  final int allocated;
  final DateTime? firstEventDate;
  final int firstEventAllocated;
  final int coveredOccurrences;
  final DateTime? coveredThrough;
  final DateTime? nextUncoveredDate;
  final int nextUncoveredAllocated;
}

class GoalSnapshot {
  const GoalSnapshot({
    this.goals = const [],
    this.coverage = const {},
    this.balances = const {},
    this.accountNames = const {},
  });

  final List<GoalPlan> goals;
  final Map<int, GoalCoverage> coverage;
  final Map<int, int> balances;
  final Map<int, String> accountNames;
}

class _MutableCoverage {
  _MutableCoverage(GoalPlan goal)
    : firstEventDate = goal.dueDate,
      nextUncoveredDate = goal.dueDate;
  final DateTime firstEventDate;
  int allocated = 0;
  int firstEventAllocated = 0;
  int coveredOccurrences = 0;
  DateTime? coveredThrough;
  DateTime? nextUncoveredDate;
  int nextUncoveredAllocated = 0;
  bool firstProcessed = false;

  void process(GoalPlan goal, DateTime date, int amount, DateTime? next) {
    allocated += amount;
    if (!firstProcessed) {
      firstEventAllocated = amount;
      firstProcessed = true;
    }
    if (amount >= goal.target) {
      coveredOccurrences++;
      coveredThrough = date;
      nextUncoveredDate = next;
      nextUncoveredAllocated = 0;
    } else {
      nextUncoveredDate = date;
      nextUncoveredAllocated = amount;
    }
  }

  GoalCoverage freeze() => GoalCoverage(
    allocated: allocated,
    firstEventDate: firstEventDate,
    firstEventAllocated: firstEventAllocated,
    coveredOccurrences: coveredOccurrences,
    coveredThrough: coveredThrough,
    nextUncoveredDate: nextUncoveredDate,
    nextUncoveredAllocated: nextUncoveredAllocated,
  );
}

/// Assigns existing money to future events in date order. Events on one date
/// share available money equally, capped at each event's target. Repeats are
/// expanded until the balance is spent.
Map<int, GoalCoverage> allocateGoalEvents(
  List<GoalPlan> goals,
  Map<int, int> balances, {
  DateTime? through,
}) {
  final active = goals.where((g) => g.isActive && g.accountId != null).toList();
  final mutable = {for (final goal in active) goal.id: _MutableCoverage(goal)};
  final accountGroups = <int, List<GoalPlan>>{};
  for (final goal in active) {
    accountGroups.putIfAbsent(goal.accountId!, () => []).add(goal);
  }
  for (final entry in accountGroups.entries) {
    _allocateEventGroup(
      entry.value,
      mutable,
      through: through,
      money: math.max(0, balances[entry.key] ?? 0),
    );
  }
  return {for (final entry in mutable.entries) entry.key: entry.value.freeze()};
}

void _allocateEventGroup(
  List<GoalPlan> goals,
  Map<int, _MutableCoverage> coverages, {
  required DateTime? through,
  int? money,
}) {
  var available = money ?? 0;
  final queue = <int, DateTime>{
    for (final goal in goals)
      if (through == null || !goal.dueDate.isAfter(through))
        goal.id: goal.dueDate,
  };
  while (queue.isNotEmpty && available > 0) {
    final date = queue.values.reduce((a, b) => a.isBefore(b) ? a : b);
    if (through != null && date.isAfter(through)) break;
    final todays = goals.where((g) => queue[g.id] == date).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final skipped = _skipAlignedCycles(
      queue: queue,
      todays: todays,
      date: date,
      available: available,
      through: through,
      coverages: coverages,
    );
    if (skipped > 0) {
      final cost = todays.fold<int>(0, (sum, goal) => sum + goal.target);
      available -= skipped * cost;
      continue;
    }

    final shares = _shareEventMoney(todays, available);
    for (final goal in todays) {
      final saved = shares[goal.id] ?? 0;
      final next = goal.intervalUnit == null
          ? null
          : nextGoalDeadline(goal, date.add(const Duration(days: 1)));
      coverages[goal.id]!.process(goal, date, saved, next);
      if (saved >= goal.target &&
          next != null &&
          (through == null || !next.isAfter(through))) {
        queue[goal.id] = next;
      } else {
        queue.remove(goal.id);
      }
    }
    available -= shares.values.fold<int>(0, (sum, value) => sum + value);
    if (todays.any((goal) => (shares[goal.id] ?? 0) < goal.target)) {
      // A partially funded date consumes the remaining pool. Later events
      // cannot receive money until another real balance change occurs.
      break;
    }
  }
}

Map<int, int> _shareEventMoney(List<GoalPlan> goals, int available) {
  final shares = {for (final goal in goals) goal.id: 0};
  final pending = [...goals]..sort((a, b) => a.id.compareTo(b.id));
  var remaining = available;
  while (pending.isNotEmpty && remaining > 0) {
    final equal = remaining ~/ pending.length;
    if (equal == 0) {
      for (var i = 0; i < remaining; i++) {
        shares[pending[i].id] = shares[pending[i].id]! + 1;
      }
      break;
    }
    final capped = pending
        .where((g) => g.target - shares[g.id]! <= equal)
        .toList();
    if (capped.isNotEmpty) {
      for (final goal in capped) {
        final amount = goal.target - shares[goal.id]!;
        shares[goal.id] = shares[goal.id]! + amount;
        remaining -= amount;
        pending.remove(goal);
      }
      continue;
    }
    final remainder = remaining % pending.length;
    for (var i = 0; i < pending.length; i++) {
      shares[pending[i].id] =
          shares[pending[i].id]! + equal + (i < remainder ? 1 : 0);
    }
    remaining = 0;
  }
  return shares;
}

int _skipAlignedCycles({
  required Map<int, DateTime> queue,
  required List<GoalPlan> todays,
  required DateTime date,
  required int available,
  required DateTime? through,
  required Map<int, _MutableCoverage> coverages,
}) {
  if (todays.isEmpty || todays.any((g) => g.intervalUnit == null)) return 0;
  final first = todays.first;
  if (todays.any(
    (g) =>
        g.intervalUnit != first.intervalUnit ||
        g.intervalCount != first.intervalCount ||
        g.anchorDate.day != first.anchorDate.day ||
        (g.intervalUnit == 'year' &&
            g.anchorDate.month != first.anchorDate.month),
  )) {
    return 0;
  }
  final next = nextGoalDeadline(first, date.add(const Duration(days: 1)));
  if (todays.any(
    (g) => nextGoalDeadline(g, date.add(const Duration(days: 1))) != next,
  )) {
    return 0;
  }
  final eventCost = todays.fold<int>(0, (sum, goal) => sum + goal.target);
  if (eventCost <= 0) return 0;
  var count = available ~/ eventCost;
  if (count < 2) return 0;

  DateTime? boundary;
  for (final entry in queue.entries) {
    if (todays.any((g) => g.id == entry.key)) continue;
    if (boundary == null || entry.value.isBefore(boundary)) {
      boundary = entry.value;
    }
  }
  if (through != null) {
    final after = through.add(const Duration(days: 1));
    if (boundary == null || after.isBefore(boundary)) boundary = after;
  }
  if (boundary != null) {
    final firstIndex = _occurrenceIndex(first, date);
    var upper = switch (first.intervalUnit) {
      'day' => (calendarDays(date, boundary) / first.intervalCount).ceil(),
      'week' =>
        (calendarDays(date, boundary) / (7 * first.intervalCount)).ceil(),
      'year' || 'month' => 1,
      _ => 0,
    };
    if (first.intervalUnit == 'month' || first.intervalUnit == 'year') {
      final monthGap =
          (boundary.year - date.year) * 12 + boundary.month - date.month;
      upper =
          monthGap ~/
              (first.intervalCount * (first.intervalUnit == 'year' ? 12 : 1)) +
          2;
    }
    upper = math.max(0, upper);
    // Correct the month-end approximation around clipped dates.
    while (upper > 0 &&
        goalOccurrence(
          first,
          firstIndex + upper - 1,
        ).isAfter(boundary.subtract(const Duration(days: 1)))) {
      upper--;
    }
    while (goalOccurrence(first, firstIndex + upper).isBefore(boundary)) {
      upper++;
    }
    count = math.min(count, upper);
  }
  if (count < 2) return 0;
  for (final goal in todays) {
    final index = _occurrenceIndex(goal, date);
    final lastDate = goalOccurrence(goal, index + count - 1);
    final nextDate = goalOccurrence(goal, index + count);
    final coverage = coverages[goal.id]!;
    if (!coverage.firstProcessed) {
      coverage.firstProcessed = true;
      coverage.firstEventAllocated = goal.target;
    }
    coverage.allocated += count * goal.target;
    coverage.coveredOccurrences += count;
    coverage.coveredThrough = lastDate;
    coverage.nextUncoveredDate = through != null && nextDate.isAfter(through)
        ? null
        : nextDate;
    coverage.nextUncoveredAllocated = 0;
    queue[goal.id] = nextDate;
  }
  return count;
}

int _occurrenceIndex(GoalPlan goal, DateTime date) {
  if (goal.intervalUnit == 'day' || goal.intervalUnit == 'week') {
    return calendarDays(goal.anchorDate, date) ~/
        (goal.intervalCount * (goal.intervalUnit == 'week' ? 7 : 1));
  }
  final months =
      (date.year - goal.anchorDate.year) * 12 +
      date.month -
      goal.anchorDate.month;
  return months ~/
      (goal.intervalCount * (goal.intervalUnit == 'year' ? 12 : 1));
}

/// One-event allocator used by legacy calculations and integrations.
Map<int, int> allocateGoals(List<GoalPlan> goals, Map<int, int> balances) {
  final result = <int, int>{};
  final groups = <int, List<GoalPlan>>{};
  for (final goal in goals.where((g) => g.isActive && g.accountId != null)) {
    groups.putIfAbsent(goal.accountId!, () => []).add(goal);
  }
  for (final entry in groups.entries) {
    final pending = [...entry.value]
      ..sort((a, b) => a.target.compareTo(b.target));
    var money = math.max(0, balances[entry.key] ?? 0);
    while (pending.isNotEmpty) {
      final share = money ~/ pending.length;
      if (pending.first.target <= share) {
        final goal = pending.removeAt(0);
        result[goal.id] = goal.target;
        money -= goal.target;
      } else {
        final ordered = [...pending]..sort((a, b) => a.id.compareTo(b.id));
        for (var i = 0; i < ordered.length; i++) {
          result[ordered[i].id] = share + (i < money % ordered.length ? 1 : 0);
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
double dailyGoalRate(GoalPlan goal, Object savedOrCoverage, DateTime now) {
  if (!goal.isActive) return 0;
  if (savedOrCoverage is GoalCoverage) {
    final date = savedOrCoverage.nextUncoveredDate;
    if (date == null) return 0;
    final remaining = math.max(
      0,
      goal.target - savedOrCoverage.nextUncoveredAllocated,
    );
    return remaining / math.max(1, calendarDays(now, date));
  }

  // Preserve the original helper contract for older integrations.
  final saved = savedOrCoverage is int ? savedOrCoverage : 0;
  final remaining = math.max(0, goal.target - saved);
  return remaining / math.max(1, calendarDays(now, goal.dueDate));
}
