import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/notification_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/recurring_interval.dart';
import '../../domain/entities/recurring_payment.dart';

class RecurringPaymentCard extends StatelessWidget {
  const RecurringPaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
    required this.onToggleActive,
    required this.notificationAccess,
    required this.onNotificationBlocked,
  });

  final RecurringPaymentEntity payment;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final NotificationAccess notificationAccess;
  final VoidCallback onNotificationBlocked;

  static const _months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final isIncome = payment.type == TransactionType.income;
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final active = payment.isActive;
    final sign = isIncome ? '+' : '−';
    final reminderSelected = payment.notifyValue != null;
    final blocked =
        active &&
        reminderSelected &&
        notificationAccess == NotificationAccess.disabled;
    final available =
        active &&
        reminderSelected &&
        notificationAccess == NotificationAccess.enabled;
    final reminderLabel = !reminderSelected
        ? 'Напоминание выключено'
        : !active
        ? 'Напоминание приостановлено вместе с платежом'
        : switch (notificationAccess) {
            NotificationAccess.enabled => 'Напоминание включено',
            NotificationAccess.disabled =>
              'Напоминание заблокировано. Открыть настройки',
            NotificationAccess.unsupported =>
              'Напоминания на этой платформе недоступны',
            NotificationAccess.unavailable =>
              'Не удалось проверить напоминание',
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
            child: Opacity(
              opacity: active ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${payment.categoryName} · ${payment.accountName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(value: active, onChanged: onToggleActive),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    overflowSpacing: 6,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$sign${formatMoneyAbs(payment.amount)}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          recurrenceLabel(
                            payment.intervalUnit,
                            payment.intervalCount,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        active
                            ? Icons.schedule_rounded
                            : Icons.pause_circle_outline_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          active
                              ? 'Следующий: ${_formatDate(payment.nextRunDate)}'
                              : 'Платёж приостановлен',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: reminderLabel,
                        onPressed: blocked
                            ? onNotificationBlocked
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(reminderLabel)),
                                );
                              },
                        iconSize: 20,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              available
                                  ? Icons.notifications_active_outlined
                                  : active && reminderSelected
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_off_outlined,
                              color: available
                                  ? AppColors.brand
                                  : active && reminderSelected
                                  ? AppColors.warning
                                  : AppColors.textTertiary,
                            ),
                            if (active && reminderSelected && !available)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Icon(
                                  blocked
                                      ? Icons.error_rounded
                                      : Icons.help_rounded,
                                  size: 12,
                                  color: AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
