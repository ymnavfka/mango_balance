import '../../../../core/services/notification_service.dart';
import '../../domain/entities/recurring_payment.dart';

class RecurringState {
  const RecurringState({
    required this.payments,
    this.notificationAccess = NotificationAccess.unavailable,
  });

  factory RecurringState.initial() {
    return const RecurringState(payments: []);
  }

  final List<RecurringPaymentEntity> payments;
  final NotificationAccess notificationAccess;

  RecurringState copyWith({
    List<RecurringPaymentEntity>? payments,
    NotificationAccess? notificationAccess,
  }) {
    return RecurringState(
      payments: payments ?? this.payments,
      notificationAccess: notificationAccess ?? this.notificationAccess,
    );
  }
}
