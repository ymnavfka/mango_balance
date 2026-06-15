import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/recurring_payment.dart';
import '../../domain/usecases/add_recurring_payment.dart';
import '../../domain/usecases/delete_recurring_payment.dart';
import '../../domain/usecases/run_due_recurring_payments.dart';
import '../../domain/usecases/set_recurring_active.dart';
import '../../domain/usecases/update_recurring_payment.dart';
import '../../domain/usecases/watch_recurring_payments.dart';
import 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit({
    required this.activeProfile,
    required this.watchRecurringPaymentsUseCase,
    required this.addRecurringPaymentUseCase,
    required this.updateRecurringPaymentUseCase,
    required this.deleteRecurringPaymentUseCase,
    required this.setRecurringActiveUseCase,
    required this.runDueRecurringPaymentsUseCase,
  }) : super(RecurringState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final WatchRecurringPayments watchRecurringPaymentsUseCase;
  final AddRecurringPayment addRecurringPaymentUseCase;
  final UpdateRecurringPayment updateRecurringPaymentUseCase;
  final DeleteRecurringPayment deleteRecurringPaymentUseCase;
  final SetRecurringActive setRecurringActiveUseCase;
  final RunDueRecurringPayments runDueRecurringPaymentsUseCase;

  StreamSubscription<List<RecurringPaymentEntity>>? _subscription;
  late final StreamSubscription<int> _profileSubscription;

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  Future<void> _resubscribe(int profileId) async {
    await _subscription?.cancel();
    emit(RecurringState.initial());

    // Материализуем наступившие платежи до показа списка, чтобы созданные
    // транзакции сразу попали в общий список и баланс.
    await _runDueSafely(profileId);

    _subscription = watchRecurringPaymentsUseCase(profileId).listen((list) {
      emit(state.copyWith(payments: list));
    });
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
    await _subscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
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
