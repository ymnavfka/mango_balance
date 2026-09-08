import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/active_profile_holder.dart';
import '../../../../core/services/notification_service.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/recurring_payment.dart';
import '../../domain/reminder_time.dart';
import '../../domain/usecases/add_recurring_payment.dart';
import '../../domain/usecases/delete_recurring_payment.dart';
import '../../domain/usecases/run_due_recurring_payments.dart';
import '../../domain/usecases/set_recurring_active.dart';
import '../../domain/usecases/update_recurring_payment.dart';
import '../../domain/usecases/watch_recurring_payments.dart';
import 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> with WidgetsBindingObserver {
  RecurringCubit({
    required this.activeProfile,
    required this.watchRecurringPaymentsUseCase,
    required this.addRecurringPaymentUseCase,
    required this.updateRecurringPaymentUseCase,
    required this.deleteRecurringPaymentUseCase,
    required this.setRecurringActiveUseCase,
    required this.runDueRecurringPaymentsUseCase,
    required this.notificationService,
  }) : super(RecurringState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final NotificationService notificationService;
  final WatchRecurringPayments watchRecurringPaymentsUseCase;
  final AddRecurringPayment addRecurringPaymentUseCase;
  final UpdateRecurringPayment updateRecurringPaymentUseCase;
  final DeleteRecurringPayment deleteRecurringPaymentUseCase;
  final SetRecurringActive setRecurringActiveUseCase;
  final RunDueRecurringPayments runDueRecurringPaymentsUseCase;

  StreamSubscription<List<RecurringPaymentEntity>>? _subscription;
  late final StreamSubscription<int> _profileSubscription;

  Future<void> _notificationQueue = Future.value();
  int _profileGeneration = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNotifications());
    }
  }

  Future<void> syncNotifications() => _syncNotifications(state.payments);

  void _init() {
    WidgetsBinding.instance.addObserver(this);
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  Future<void> _resubscribe(int profileId) async {
    final generation = ++_profileGeneration;
    await _subscription?.cancel();
    if (isClosed || generation != _profileGeneration) return;
    emit(RecurringState.initial());

    // Материализуем наступившие платежи до показа списка, чтобы созданные
    // транзакции сразу попали в общий список и баланс.
    await _runDueSafely(profileId);

    if (isClosed || generation != _profileGeneration) return;
    _subscription = watchRecurringPaymentsUseCase(profileId).listen((list) {
      if (isClosed || generation != _profileGeneration) return;
      emit(state.copyWith(payments: list));
      unawaited(_syncNotifications(list));
    });
  }

  /// Перепланирует локальные оповещения под текущий список платежей активного
  /// профиля: снимает старые и ставит новые для активных платежей с настроенным
  /// упреждением. Вызывается при любом изменении списка (добавление, правка,
  /// удаление, включение/выключение, материализация наступивших дат).
  Future<void> _syncNotifications(List<RecurringPaymentEntity> payments) {
    final generation = _profileGeneration;
    // Сериализация исключает перемешивание cancelAll/schedule при сохранении,
    // возврате из системного диалога и переключении профиля.
    _notificationQueue = _notificationQueue.then((_) async {
      if (isClosed || generation != _profileGeneration) return;
      try {
        final access = await notificationService.access();
        if (isClosed || generation != _profileGeneration) return;
        emit(state.copyWith(notificationAccess: access));
        await notificationService.cancelAll();
        if (access != NotificationAccess.enabled) return;
        for (final payment in payments) {
          if (isClosed || generation != _profileGeneration) return;
          if (!payment.isActive) continue;
          final when = reminderTimeFor(payment);
          if (when == null) continue;
          await notificationService.schedule(
            id: payment.id,
            title: payment.name,
            body: _reminderBody(payment),
            when: when,
          );
        }
      } catch (_) {
        if (!isClosed && generation == _profileGeneration) {
          emit(
            state.copyWith(notificationAccess: NotificationAccess.unavailable),
          );
        }
      }
    });
    return _notificationQueue;
  }

  String _reminderBody(RecurringPaymentEntity payment) {
    final verb = payment.type == TransactionType.expense
        ? 'Списание'
        : 'Пополнение';
    final d = payment.nextRunDate;
    final date =
        '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
    return '$verb ${formatMoneyAbs(payment.amount)} — $date';
  }

  /// Планировщик — лучшая попытка: его сбой не должен ломать загрузку экрана.
  Future<void> _runDueSafely(int profileId) async {
    try {
      await runDueRecurringPaymentsUseCase(profileId);
    } catch (_) {
      // Несоздавшиеся платежи будут материализованы при следующем запуске.
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    ++_profileGeneration;
    await _subscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  /// Только сохранение новой формы может вызвать системный запрос.
  /// Восстановление удалённого платежа использует addRecurringPayment.
  Future<void> createRecurringPayment(RecurringPaymentEntity payment) async {
    await addRecurringPayment(payment);
    if (payment.isActive && payment.notifyValue != null) {
      await notificationService.requestPermissions();
      await syncNotifications();
    }
  }

  Future<void> addRecurringPayment(RecurringPaymentEntity payment) async {
    await addRecurringPaymentUseCase(payment);
    await _runDueSafely(activeProfile.id);
  }

  Future<void> updateRecurringPayment(RecurringPaymentEntity payment) async {
    await updateRecurringPaymentUseCase(payment);
    await _runDueSafely(activeProfile.id);
  }

  Future<void> deleteRecurringPayment(int id) async {
    await deleteRecurringPaymentUseCase(id);
  }

  Future<void> setActive(int id, bool active) async {
    await setRecurringActiveUseCase(id, active);
    if (active) {
      await _runDueSafely(activeProfile.id);
    }
  }
}
