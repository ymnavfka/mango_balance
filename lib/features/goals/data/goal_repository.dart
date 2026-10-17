import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/goal.dart';

GoalPlan goalFromRow(Goal row) => GoalPlan(
  id: row.id,
  profileId: row.profileId,
  name: row.name,
  target: row.target,
  dueDate: row.dueDate,
  anchorDate: row.anchorDate,
  intervalUnit: row.intervalUnit,
  intervalCount: row.intervalCount,
  accountId: row.accountId,
  manualSaved: row.manualSaved,
  status: row.status,
  savedSnapshot: row.savedSnapshot,
  savedOccurrenceCount: row.savedOccurrenceCount,
  savedThroughDate: row.savedThroughDate,
  sourcePaymentId: row.sourcePaymentId,
);

class GoalSnapshot {
  const GoalSnapshot({
    this.goals = const [],
    this.coverage = const {},
    this.allocations = const {},
    this.balances = const {},
    this.accountNames = const {},
  });
  final List<GoalPlan> goals;
  final Map<int, GoalCoverage> coverage;

  /// Kept for older callers; new code should use [coverage].
  final Map<int, int> allocations;
  final Map<int, int> balances;
  final Map<int, String> accountNames;
}

class GoalRepository {
  GoalRepository(this.db);
  final AppDatabase db;

  Future<List<GoalPlan>> _goals(int profileId) async =>
      (await (db.select(
            db.goals,
          )..where((g) => g.profileId.equals(profileId))).get())
          .map(goalFromRow)
          .toList();

  Future<Map<int, int>> _balances(int profileId, {DateTime? through}) async {
    final accounts = await (db.select(
      db.accounts,
    )..where((a) => a.profileId.equals(profileId))).get();
    final balances = {
      for (final a in accounts) a.id: (a.initialBalance * 100).round(),
    };
    final query = db.select(db.transactions)
      ..where((t) => t.profileId.equals(profileId));
    if (through != null) {
      query.where(
        (t) => t.date.isSmallerThanValue(
          DateTime(through.year, through.month, through.day + 1),
        ),
      );
    }
    for (final tx in await query.get()) {
      final amount = (tx.amount * 100).round();
      balances.update(
        tx.accountId,
        (v) => v + (tx.type == 'income' ? amount : -amount),
        ifAbsent: () => 0,
      );
      if (tx.type == 'transfer') {
        balances.update(
          tx.toAccountId,
          (v) => v + amount,
          ifAbsent: () => amount,
        );
      }
    }
    return balances;
  }

  Future<GoalSnapshot> load(
    int profileId, {
    DateTime? now,
  }) => db.transaction(() async {
    final today = goalDay(now ?? DateTime.now());
    var goals = await _goals(profileId);

    // Freeze one-off goals at their due date. Repeating goals contribute
    // only their next event on or after that simulated date.
    final expiredDates =
        goals
            .where(
              (g) =>
                  g.isActive &&
                  g.intervalUnit == null &&
                  g.dueDate.isBefore(today),
            )
            .map((g) => goalDay(g.dueDate))
            .toSet()
            .toList()
          ..sort();
    for (final date in expiredDates) {
      final atDate = goals.map((g) {
        if (!g.isActive ||
            g.intervalUnit == null ||
            !g.dueDate.isBefore(date)) {
          return g;
        }
        return GoalPlan(
          id: g.id,
          profileId: g.profileId,
          name: g.name,
          target: g.target,
          dueDate: nextGoalDeadline(g, date),
          anchorDate: g.anchorDate,
          intervalUnit: g.intervalUnit,
          intervalCount: g.intervalCount,
          accountId: g.accountId,
          manualSaved: g.manualSaved,
        );
      }).toList();
      final snapshot = allocateGoalEvents(
        atDate,
        await _balances(profileId, through: date),
        through: date,
      );
      for (final goal in goals.where(
        (g) =>
            g.isActive && g.intervalUnit == null && goalDay(g.dueDate) == date,
      )) {
        final coverage = snapshot[goal.id] ?? const GoalCoverage();
        await (db.update(db.goals)..where((g) => g.id.equals(goal.id))).write(
          GoalsCompanion(
            status: const Value('completed'),
            savedSnapshot: Value(coverage.allocated),
            savedOccurrenceCount: Value(coverage.coveredOccurrences),
            savedThroughDate: Value(coverage.coveredThrough),
          ),
        );
      }
      goals = await _goals(profileId);
    }

    // Events that elapsed while the app was closed disappear. Keep the
    // manually entered balance: the user decides whether the money was spent.
    for (final goal in goals.where(
      (g) => g.isActive && g.intervalUnit != null && g.dueDate.isBefore(today),
    )) {
      await (db.update(db.goals)..where((g) => g.id.equals(goal.id))).write(
        GoalsCompanion(dueDate: Value(nextGoalDeadline(goal, today))),
      );
    }
    goals = await _goals(profileId);
    final balances = await _balances(profileId);
    final accounts = await (db.select(
      db.accounts,
    )..where((a) => a.profileId.equals(profileId))).get();

    // Heal stale/imported references using the last full future allocation.
    final unavailable = accounts
        .where((a) => a.isArchived)
        .map((a) => a.id)
        .toSet();
    final available = accounts.map((a) => a.id).toSet();
    final coverage = allocateGoalEvents(goals, balances);
    for (final goal in goals.where(
      (g) =>
          g.accountId != null &&
          (unavailable.contains(g.accountId) ||
              !available.contains(g.accountId)),
    )) {
      final saved = coverage[goal.id] ?? const GoalCoverage();
      await (db.update(db.goals)..where((g) => g.id.equals(goal.id))).write(
        GoalsCompanion(
          accountId: const Value(null),
          status: Value(goal.isActive ? 'paused' : goal.status),
          manualSaved: const Value(0),
          savedSnapshot: Value(
            goal.isActive ? saved.allocated : goal.savedSnapshot,
          ),
          savedOccurrenceCount: Value(
            goal.isActive
                ? saved.coveredOccurrences
                : goal.savedOccurrenceCount,
          ),
          savedThroughDate: Value(
            goal.isActive ? saved.coveredThrough : goal.savedThroughDate,
          ),
        ),
      );
    }
    goals = await _goals(profileId);
    return GoalSnapshot(
      goals: goals,
      coverage: allocateGoalEvents(goals, balances),
      balances: balances,
      accountNames: {for (final a in accounts) a.id: a.name},
    );
  });

  Future<void> save(GoalPlan goal, {DateTime? now}) => db.transaction(() async {
    if (goal.name.trim().isEmpty ||
        goal.target <= 0 ||
        goal.target > 900000000000000 ||
        goal.manualSaved < 0 ||
        goal.intervalCount < 1 ||
        goal.intervalCount > 10000 ||
        !['active', 'paused', 'completed'].contains(goal.status) ||
        (goal.intervalUnit != null &&
            !['day', 'week', 'month', 'year'].contains(goal.intervalUnit))) {
      throw Exception('Проверьте параметры цели');
    }
    if (goal.isActive &&
        goalDay(goal.dueDate).isBefore(goalDay(now ?? DateTime.now()))) {
      throw Exception('Выберите сегодняшнюю или будущую дату');
    }
    if (goal.accountId != null) {
      final account = await db.accountById(goal.accountId!);
      if (account == null ||
          account.isArchived ||
          account.profileId != goal.profileId) {
        throw Exception('Выберите доступный счёт');
      }
    }
    if (goal.sourcePaymentId != null) {
      final source = await db.recurringPaymentById(goal.sourcePaymentId!);
      if (source == null ||
          source.profileId != goal.profileId ||
          source.type != 'expense') {
        throw Exception('Исходный платёж больше недоступен');
      }
    }
    if (goal.sourcePaymentId != null) {
      final duplicate =
          await (db.select(db.goals)..where(
                (g) =>
                    g.sourcePaymentId.equals(goal.sourcePaymentId!) &
                    g.id.isNotValue(goal.id),
              ))
              .getSingleOrNull();
      if (duplicate != null) {
        throw Exception('Для этого платежа уже создана цель');
      }
    }
    final row = GoalsCompanion(
      profileId: Value(goal.profileId),
      name: Value(goal.name.trim()),
      target: Value(goal.target),
      dueDate: Value(goalDay(goal.dueDate)),
      anchorDate: Value(goalDay(goal.anchorDate)),
      intervalUnit: Value(goal.intervalUnit),
      intervalCount: Value(goal.intervalCount),
      accountId: Value(goal.accountId),
      manualSaved: Value(goal.accountId == null ? goal.manualSaved : 0),
      status: Value(goal.status),
      savedSnapshot: Value(goal.savedSnapshot),
      savedOccurrenceCount: Value(goal.savedOccurrenceCount),
      savedThroughDate: Value(goal.savedThroughDate),
      sourcePaymentId: Value(goal.sourcePaymentId),
    );
    if (goal.id == 0) {
      await db.into(db.goals).insert(row);
    } else {
      await (db.update(db.goals)..where(
            (g) => g.id.equals(goal.id) & g.profileId.equals(goal.profileId),
          ))
          .write(row);
    }
  });

  Future<void> complete(int id, int profileId) => db.transaction(() async {
    final snapshot = await load(profileId);
    final coverage = snapshot.coverage[id] ?? const GoalCoverage();
    await (db.update(
      db.goals,
    )..where((g) => g.id.equals(id) & g.profileId.equals(profileId))).write(
      GoalsCompanion(
        status: const Value('completed'),
        savedSnapshot: Value(coverage.allocated),
        savedOccurrenceCount: Value(coverage.coveredOccurrences),
        savedThroughDate: Value(coverage.coveredThrough),
      ),
    );
  });

  Future<void> delete(int id, int profileId) async {
    await (db.delete(
      db.goals,
    )..where((g) => g.id.equals(id) & g.profileId.equals(profileId))).go();
  }

  /// Called before account mutations, inside the same transaction.
  Future<void> detachAccount(int accountId, int profileId) async {
    final snapshot = await load(profileId);
    for (final goal in snapshot.goals.where((g) => g.accountId == accountId)) {
      final coverage = snapshot.coverage[goal.id] ?? const GoalCoverage();
      await (db.update(db.goals)..where((g) => g.id.equals(goal.id))).write(
        GoalsCompanion(
          accountId: const Value(null),
          manualSaved: const Value(0),
          status: Value(goal.isActive ? 'paused' : goal.status),
          savedSnapshot: Value(
            goal.isActive ? coverage.allocated : goal.savedSnapshot,
          ),
          savedOccurrenceCount: Value(
            goal.isActive
                ? coverage.coveredOccurrences
                : goal.savedOccurrenceCount,
          ),
          savedThroughDate: Value(
            goal.isActive ? coverage.coveredThrough : goal.savedThroughDate,
          ),
        ),
      );
    }
  }
}
