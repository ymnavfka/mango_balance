import '../../../../core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/undo_snackbar.dart';
import '../../domain/entities/recurring_payment.dart';
import '../cubit/recurring_cubit.dart';
import '../cubit/recurring_state.dart';
import '../widgets/recurring_payment_card.dart';
import '../widgets/recurring_payment_form_dialog.dart';
import '../widgets/recurring_summary_card.dart';
import '../widgets/notification_access_hint.dart';

class RecurringPaymentsPage extends StatelessWidget {
  const RecurringPaymentsPage({super.key});

  void _openForm(BuildContext context, {RecurringPaymentEntity? initial}) {
    final cubit = context.read<RecurringCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecurringPaymentFormDialog(
        initial: initial,
        onSubmit: (payment) async {
          if (initial == null) {
            await cubit.createRecurringPayment(payment);
          } else {
            await cubit.updateRecurringPayment(payment);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.recurring),
      appBar: AppBar(title: const Text('Регулярные платежи')),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          if (state.payments.isEmpty) {
            return const EmptyState(
              icon: Icons.event_repeat_rounded,
              title: 'Регулярных платежей пока нет',
              message:
                  'Создайте платёж, и транзакции будут добавляться '
                  'автоматически в нужные даты — зарплата, подписки, аренда.',
            );
          }
          return Column(
            children: [
              if (state.payments.any(
                    (p) => p.isActive && p.notifyValue != null,
                  ) &&
                  state.notificationAccess != NotificationAccess.enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: NotificationAccessHint(
                    access: state.notificationAccess,
                  ),
                ),
              RecurringSummaryCard(payments: state.payments),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: state.payments.length,
                  itemBuilder: (context, index) {
                    final payment = state.payments[index];
                    return Dismissible(
                      key: ValueKey(payment.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        final cubit = context.read<RecurringCubit>();
                        cubit.deleteRecurringPayment(payment.id);
                        showUndoSnackBar(
                          context,
                          message: 'Платёж удалён',
                          onUndo: () => cubit.addRecurringPayment(payment),
                        );
                      },
                      child: RecurringPaymentCard(
                        payment: payment,
                        notificationAccess: state.notificationAccess,
                        onNotificationBlocked: () =>
                            showNotificationHelp(context),
                        onTap: () => _openForm(context, initial: payment),
                        onToggleActive: (value) => context
                            .read<RecurringCubit>()
                            .setActive(payment.id, value),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Платёж'),
      ),
    );
  }
}
