import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_error_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../cubit/recurring_cubit.dart';

Future<void> openNotificationSettings(BuildContext context) async {
  final cubit = context.read<RecurringCubit>();
  final opened = await cubit.notificationService.openSettings();
  if (!opened) {
    showAppNotice('Не удалось открыть настройки уведомлений');
  }
}

Future<void> showNotificationHelp(BuildContext context) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Напоминания заблокированы'),
      content: const Text('Разрешите уведомления, чтобы получать напоминания.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Открыть настройки'),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) await openNotificationSettings(context);
}

class NotificationAccessHint extends StatelessWidget {
  const NotificationAccessHint({
    super.key,
    required this.access,
    this.inForm = false,
  });

  final NotificationAccess access;
  final bool inForm;

  @override
  Widget build(BuildContext context) {
    if (access == NotificationAccess.enabled) return const SizedBox.shrink();
    final blocked = access == NotificationAccess.disabled;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          switch (access) {
            NotificationAccess.disabled =>
              inForm ? 'Нет разрешения' : 'Напоминания заблокированы',
            NotificationAccess.unsupported => 'Напоминания здесь недоступны',
            _ => 'Не удалось проверить напоминания',
          },
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (blocked)
          TextButton(
            onPressed: () => openNotificationSettings(context),
            child: const Text('Настройки'),
          ),
        if (access == NotificationAccess.unavailable)
          TextButton(
            onPressed: () => context.read<RecurringCubit>().syncNotifications(),
            child: const Text('Повторить'),
          ),
      ],
    );
  }
}
