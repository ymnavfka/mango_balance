import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/core/services/active_profile_holder.dart';
import 'package:mango_balance/core/services/notification_service.dart';
import 'package:mango_balance/features/recurring/domain/entities/notify_lead.dart';
import 'package:mango_balance/features/recurring/domain/entities/recurring_interval.dart';
import 'package:mango_balance/features/recurring/domain/entities/recurring_payment.dart';
import 'package:mango_balance/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:mango_balance/features/recurring/domain/usecases/add_recurring_payment.dart';
import 'package:mango_balance/features/recurring/domain/usecases/delete_recurring_payment.dart';
import 'package:mango_balance/features/recurring/domain/usecases/run_due_recurring_payments.dart';
import 'package:mango_balance/features/recurring/domain/usecases/set_recurring_active.dart';
import 'package:mango_balance/features/recurring/domain/usecases/update_recurring_payment.dart';
import 'package:mango_balance/features/recurring/domain/usecases/watch_recurring_payments.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_cubit.dart';

class MemoryRecurring extends Fake implements RecurringRepository {
  final changes = StreamController<List<RecurringPaymentEntity>>.broadcast();
  final payments = <RecurringPaymentEntity>[];
  bool fail = false;

  @override
  Stream<List<RecurringPaymentEntity>> watchRecurringPayments(int profileId) =>
      changes.stream;

  @override
  Future<void> addRecurringPayment(RecurringPaymentEntity payment) async {
    if (fail) throw StateError('save failed');
    payments.add(payment);
    changes.add(List.of(payments));
  }

  @override
  Future<void> updateRecurringPayment(RecurringPaymentEntity payment) async {
    payments[0] = payment;
    changes.add(List.of(payments));
  }
}

class NoDuePayments extends Fake implements RunDueRecurringPayments {
  @override
  Future<void> call(int profileId, {DateTime? now}) async {}
}

class FakeNotifications extends NotificationService {
  NotificationAccess status = NotificationAccess.disabled;
  int requests = 0;
  final scheduled = <int>[];

  @override
  Future<NotificationAccess> access() async => status;

  @override
  Future<NotificationAccess> requestPermissions() async {
    requests++;
    return status;
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async => scheduled.add(id);
}

RecurringPaymentEntity payment({bool notify = true, bool active = true}) {
  final date = DateTime.now().add(const Duration(days: 30));
  return RecurringPaymentEntity(
    id: 1,
    name: 'Rent',
    type: TransactionType.expense,
    amount: 100,
    categoryId: 1,
    categoryName: 'Home',
    accountId: 1,
    accountName: 'Cash',
    intervalUnit: RecurringInterval.month,
    intervalCount: 1,
    startDate: date,
    nextRunDate: date,
    isActive: active,
    notifyValue: notify ? 1 : null,
    notifyUnit: notify ? NotifyLeadUnit.day : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRecurring repository;
  late FakeNotifications notifications;
  late ActiveProfileHolder profile;
  late RecurringCubit cubit;

  setUp(() async {
    repository = MemoryRecurring();
    notifications = FakeNotifications();
    profile = ActiveProfileHolder(initialId: 1);
    cubit = RecurringCubit(
      activeProfile: profile,
      notificationService: notifications,
      watchRecurringPaymentsUseCase: WatchRecurringPayments(repository),
      addRecurringPaymentUseCase: AddRecurringPayment(repository),
      updateRecurringPaymentUseCase: UpdateRecurringPayment(repository),
      deleteRecurringPaymentUseCase: DeleteRecurringPayment(repository),
      setRecurringActiveUseCase: SetRecurringActive(repository),
      runDueRecurringPaymentsUseCase: NoDuePayments(),
    );
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    await cubit.close();
    await profile.close();
    await repository.changes.close();
  });

  test('denial preserves the payment and reminder preference', () async {
    await cubit.createRecurringPayment(payment());
    expect(repository.payments.single.notifyValue, 1);
    expect(notifications.requests, 1);
    expect(notifications.scheduled, isEmpty);
    expect(cubit.state.notificationAccess, NotificationAccess.disabled);
  });

  test(
    'no requests for disabled reminders, inactive payments, undo or edit',
    () async {
      await cubit.createRecurringPayment(payment(notify: false));
      await cubit.createRecurringPayment(payment(active: false));
      await cubit.addRecurringPayment(payment());
      await cubit.updateRecurringPayment(payment());
      await cubit.syncNotifications();
      expect(notifications.requests, 0);
    },
  );

  test('failed save never asks for permission', () async {
    repository.fail = true;
    await expectLater(
      cubit.createRecurringPayment(payment()),
      throwsStateError,
    );
    expect(notifications.requests, 0);
  });

  test(
    'resume restores future reminders, revocation cancels without prompting',
    () async {
      await cubit.addRecurringPayment(payment());
      await cubit.syncNotifications();
      expect(notifications.scheduled, isEmpty);
      notifications.status = NotificationAccess.enabled;
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await cubit.syncNotifications();
      expect(notifications.scheduled, [1]);
      notifications.status = NotificationAccess.disabled;
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await cubit.syncNotifications();
      expect(notifications.scheduled, isEmpty);
      expect(repository.payments.single.notifyValue, 1);
      expect(notifications.requests, 0);
    },
  );
}
