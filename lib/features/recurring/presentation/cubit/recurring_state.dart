import '../../domain/entities/recurring_payment.dart';

class RecurringState {
  const RecurringState({required this.payments});

  factory RecurringState.initial() {
    return const RecurringState(payments: []);
  }

  final List<RecurringPaymentEntity> payments;

  RecurringState copyWith({List<RecurringPaymentEntity>? payments}) {
    return RecurringState(payments: payments ?? this.payments);
  }
}
