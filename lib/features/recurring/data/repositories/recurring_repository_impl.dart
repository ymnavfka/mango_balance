import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/recurring_interval.dart';
import '../../domain/entities/recurring_payment.dart';
import '../../domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this.db, this.activeProfile);

  final AppDatabase db;
  final ActiveProfileHolder activeProfile;

  static const int _maxRollForward = 100000;

  @override
  Stream<List<RecurringPaymentEntity>> watchRecurringPayments(int profileId) {
    return db
        .watchRecurringPaymentsByProfile(profileId)
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<List<RecurringPaymentEntity>> activePayments(int profileId) async {
    final rows = await db.activeRecurringPaymentsByProfile(profileId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> addRecurringPayment(RecurringPaymentEntity payment) async {
    final start = _dateOnly(payment.startDate);
    final next = _rollForwardToToday(
      start,
      payment.intervalUnit,
      payment.intervalCount,
    );
    await db.insertRecurringPayment(
      RecurringPaymentsCompanion.insert(
        name: payment.name.trim(),
        type: _typeKey(payment.type),
        amount: payment.amount,
        intervalUnit: payment.intervalUnit.storageKey,
        startDate: start,
        nextRunDate: next,
        profileId: Value(activeProfile.id),
        categoryId: Value(payment.categoryId),
        accountId: Value(payment.accountId),
        intervalCount: Value(payment.intervalCount),
        isActive: Value(payment.isActive),
      ),
    );
  }

  @override
  Future<void> updateRecurringPayment(RecurringPaymentEntity payment) async {
    final existing = await db.recurringPaymentById(payment.id);
    if (existing == null) return;

    final start = _dateOnly(payment.startDate);
    final next = _rollForwardToToday(
      start,
      payment.intervalUnit,
      payment.intervalCount,
    );
    await db.updateRecurringPaymentRow(
      RecurringPayment(
        id: payment.id,
        profileId: existing.profileId,
        name: payment.name.trim(),
        type: _typeKey(payment.type),
        amount: payment.amount,
        categoryId: payment.categoryId,
        accountId: payment.accountId,
        intervalUnit: payment.intervalUnit.storageKey,
        intervalCount: payment.intervalCount,
        startDate: start,
        nextRunDate: next,
        isActive: payment.isActive,
      ),
    );
  }

  @override
  Future<void> deleteRecurringPayment(int id) {
    return db.deleteRecurringPayment(id);
  }

  @override
  Future<void> setActive(int id, bool active) async {
    if (!active) {
      await db.setRecurringActive(id, false);
      return;
    }

    final existing = await db.recurringPaymentById(id);
    if (existing == null) return;

    final unit = RecurringIntervalX.fromStorage(existing.intervalUnit);
    // При повторном включении пропускаем даты, выпавшие на период отключения,
    // чтобы не создавать платежи задним числом за время паузы.
    final next = _rollForwardToToday(
      existing.nextRunDate,
      unit,
      existing.intervalCount,
    );
    await db.setRecurringActiveAndNext(id, true, next);
  }

  @override
  Future<void> setNextRunDate(int id, DateTime nextRunDate) {
    return db.setRecurringNextRunDate(id, nextRunDate);
  }

  /// Сдвигает дату вперёд по периоду до первой, не раньше начала сегодняшнего
  /// дня. Так первый платёж не создаётся задним числом за период до создания.
  DateTime _rollForwardToToday(
    DateTime from,
    RecurringInterval unit,
    int count,
  ) {
    final today = _dateOnly(DateTime.now());
    var next = from;
    var guard = 0;
    while (next.isBefore(today) && guard < _maxRollForward) {
      next = nextOccurrence(next, unit, count);
      guard++;
    }
    return next;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _typeKey(TransactionType type) =>
      type == TransactionType.income ? 'income' : 'expense';

  RecurringPaymentEntity _mapToEntity(RecurringPaymentWithRefs row) {
    final payment = row.payment;
    return RecurringPaymentEntity(
      id: payment.id,
      name: payment.name,
      type: payment.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: payment.amount,
      categoryId: payment.categoryId,
      categoryName: row.category?.name ?? 'Без категории',
      accountId: payment.accountId,
      accountName: row.account?.name ?? 'Счёт',
      intervalUnit: RecurringIntervalX.fromStorage(payment.intervalUnit),
      intervalCount: payment.intervalCount,
      startDate: payment.startDate,
      nextRunDate: payment.nextRunDate,
      isActive: payment.isActive,
    );
  }
}
