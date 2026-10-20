import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/database/app_database.dart';
import 'package:mango_balance/core/services/active_profile_holder.dart';
import 'package:mango_balance/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:mango_balance/features/goals/domain/goal.dart';
import 'package:mango_balance/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:mango_balance/features/goals/domain/repositories/goal_repository.dart';
import 'package:mango_balance/features/export/data/repositories/export_repository_impl.dart';
import 'package:mango_balance/features/export/domain/entities/export_options.dart';
import 'package:mango_balance/features/import/data/parsers/xlsx_import_parser.dart';
import 'package:mango_balance/features/import/data/repositories/import_repository_impl.dart';

void main() {
  late AppDatabase db;
  late GoalRepository repo;
  late int account, category;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GoalRepositoryImpl(db);
    account = await db.insertAccount(
      AccountsCompanion.insert(
        name: 'Savings',
        initialBalance: const Value(900),
      ),
    );
    category = (await db.fallbackCategory('expense', 1))!.id;
  });
  tearDown(() => db.close());
  Future<int> add({
    int target = 100000,
    DateTime? due,
    String? repeat,
    int? source,
    int? accountId,
    bool manual = false,
    int saved = 0,
  }) async {
    final date = due ?? DateTime(2099, 10, 15);
    await repo.save(
      GoalPlan(
        id: 0,
        profileId: 1,
        name: 'Gift',
        target: target,
        dueDate: date,
        anchorDate: date,
        intervalUnit: repeat,
        accountId: manual ? null : accountId ?? account,
        manualSaved: saved,
        sourcePaymentId: source,
      ),
      now: DateTime(2026, 1, 1),
    );
    return (await db.select(db.goals).get()).last.id;
  }

  Future<int> payment() => db.insertRecurringPayment(
    RecurringPaymentsCompanion.insert(
      name: 'Birthday',
      type: 'expense',
      amount: 1000,
      categoryId: Value(category),
      accountId: Value(account),
      intervalUnit: 'year',
      startDate: DateTime(2026),
      nextRunDate: DateTime(2027),
    ),
  );

  test(
    'allocation reacts to funds and target changes without creating operations',
    () async {
      final small = await add(target: 10000), large = await add(target: 100000);
      var state = await repo.load(1, now: DateTime(2026));
      expect(
        {
          for (final e in state.coverage.entries) e.key: e.value.allocated,
        },
        {small: 10000, large: 80000},
      );
      await db.insertTransaction(
        TransactionsCompanion.insert(
          type: 'expense',
          amount: 800,
          date: DateTime(2026),
          categoryId: Value(category),
          accountId: Value(account),
          toAccountId: Value(account),
        ),
      );
      state = await repo.load(1, now: DateTime(2026));
      expect(
        {
          for (final e in state.coverage.entries) e.key: e.value.allocated,
        },
        {small: 5000, large: 5000},
      );
      expect(await db.select(db.transactions).get(), hasLength(1));
      await repo.delete(small, 1);
      expect(
        (await repo.load(1, now: DateTime(2026))).coverage[large]?.allocated,
        10000,
      );
    },
  );
  test(
    'manual balance carries forward after the deadline',
    () async {
      final id = await add(
        target: 10000,
        due: DateTime(2026, 10, 15),
        repeat: 'year',
        manual: true,
        saved: 10000,
      );
      var state = await repo.load(1, now: DateTime(2026, 10, 15, 23, 59));
      expect(state.goals.single.dueDate, DateTime(2026, 10, 15));
      expect(state.coverage[id]?.allocated, 10000);
      state = await repo.load(1, now: DateTime(2026, 10, 16));
      expect(state.goals.single.dueDate, DateTime(2027, 10, 15));
      expect(state.coverage[id]?.allocated, 10000);
      state = await repo.load(1, now: DateTime(2030, 10, 16));
      expect(state.goals.single.dueDate, DateTime(2031, 10, 15));
      expect(state.coverage[id]?.allocated, 10000);
    },
  );
  test('account linked repeat redistributes actual remaining funds', () async {
    final id = await add(
      target: 100000,
      due: DateTime(2026, 10, 15),
      repeat: 'year',
    );
    final state = await repo.load(1, now: DateTime(2026, 10, 16));
    expect(state.goals.single.dueDate, DateTime(2027, 10, 15));
    expect(state.coverage[id]?.allocated, 90000);
    expect(await db.select(db.transactions).get(), isEmpty);
  });
  test(
    'expired one-off reallocates the current balance to later goals',
    () async {
      final first = await add(due: DateTime(2026, 10, 15)),
          second = await add();
      await db.insertTransaction(
        TransactionsCompanion.insert(
          type: 'expense',
          amount: 800,
          date: DateTime(2026, 10, 16),
          categoryId: Value(category),
          accountId: Value(account),
          toAccountId: Value(account),
        ),
      );
      final state = await repo.load(1, now: DateTime(2026, 10, 17));
      final completed = state.goals.firstWhere((g) => g.id == first);
      expect(completed.status, 'completed');
      expect(state.coverage[second]?.allocated, 10000);
      final laterState = await repo.load(1, now: DateTime(2030));
      expect(
        laterState.goals.firstWhere((g) => g.id == first).status,
        'completed',
      );
      expect(laterState.coverage[second]?.allocated, 10000);
    },
  );
  test(
    'archive detaches and pauses with frozen progress; restoring account does not resume',
    () async {
      final id = await add();
      final holder = ActiveProfileHolder(initialId: 1);
      final accounts = AccountRepositoryImpl(db, holder, repo);
      final entity = (await accounts.watchAccounts(1).first).firstWhere(
        (a) => a.id == account,
      );
      await accounts.updateAccount(entity.copyWith(isArchived: true));
      final row = (await db.select(db.goals).get()).single;
      expect(row.accountId, isNull);
      expect(row.status, 'paused');
      expect(row.savedSnapshot, 90000);
      expect(row.manualSaved, 0);
      expect((await repo.load(1)).coverage.containsKey(id), isFalse);
      await accounts.updateAccount(entity);
      expect((await repo.load(1)).goals.single.status, 'paused');
      await holder.close();
    },
  );
  test('deleting account never rebinds goals to fallback', () async {
    await add();
    final holder = ActiveProfileHolder(initialId: 1);
    await AccountRepositoryImpl(db, holder, repo).deleteAccount(account);
    final goal = (await repo.load(1)).goals.single;
    expect(goal.accountId, isNull);
    expect(goal.status, 'paused');
    expect(goal.savedSnapshot, 90000);
    await holder.close();
  });
  test(
    'linked goal is independent; duplicate creation is rejected; deleting source keeps goal',
    () async {
      final source = await payment();
      final id = await add(source: source);
      await expectLater(add(source: source), throwsA(anything));
      await (db.update(db.recurringPayments)..where((r) => r.id.equals(source)))
          .write(const RecurringPaymentsCompanion(amount: Value(2000)));
      expect((await repo.load(1)).goals.single.target, 100000);
      await db.deleteRecurringPayment(source);
      final state = await repo.load(1);
      expect(state.goals.single.id, id);
      expect(state.goals.single.sourcePaymentId, isNull);
    },
  );
  test('backup restores goals and remaps account and payment links', () async {
    await add(source: await payment());
    await add(manual: true, saved: 12345);
    final bytes = (await ExportRepositoryImpl(db).buildXlsx(
      const ExportOptions(profileIds: [1], dateFrom: null, dateTo: null),
    )).bytes;
    final backup = XlsxImportParser().parse(bytes).backup!;
    expect(backup.goals, hasLength(2));
    await ImportRepositoryImpl(db).restore(backup);
    final profiles = await db.select(db.profiles).get();
    final other = profiles.last.id;
    final state = await repo.load(other);
    final linked = state.goals.firstWhere((g) => g.accountId != null);
    expect(linked.accountId, isNot(account));
    expect((await db.accountById(linked.accountId!))!.profileId, other);
    expect(
      (await db.recurringPaymentById(linked.sourcePaymentId!))!.profileId,
      other,
    );
    expect(
      state.goals.firstWhere((g) => g.accountId == null).manualSaved,
      12345,
    );
    await db.deleteProfile(other);
    expect((await repo.load(1)).goals, hasLength(2));
  });
  test('profile isolation and archive validation', () async {
    final other = await db.createProfile(
      name: 'Other',
      includeStandardData: false,
    );
    final foreign = (await db.fallbackAccount(other))!;
    await expectLater(add(accountId: foreign.id), throwsException);
    await add();
    expect((await repo.load(other)).goals, isEmpty);
    await (db.update(db.accounts)..where((a) => a.id.equals(account))).write(
      const AccountsCompanion(isArchived: Value(true)),
    );
    await expectLater(add(), throwsException);
  });
}
