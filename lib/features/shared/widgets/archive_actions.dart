import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/injector.dart';
import '../../../core/services/app_error_notifier.dart';
import '../../export/presentation/cubit/export_cubit.dart';
import '../../export/presentation/widgets/export_dialog.dart';
import '../../profiles/presentation/cubit/profile_cubit.dart';

/// Archive is reversible; permanent deletion always previews its consequences.
class ArchiveActions extends StatelessWidget {
  const ArchiveActions({
    super.key,
    required this.id,
    required this.name,
    required this.isAccount,
    required this.isArchived,
    required this.onArchiveChanged,
    required this.onDelete,
  });

  final int id;
  final String name;
  final bool isAccount;
  final bool isArchived;
  final Future<void> Function(bool) onArchiveChanged;
  final Future<void> Function() onDelete;

  Future<void> _delete(BuildContext context) async {
    final db = getIt<AppDatabase>();
    String destination;
    int operations;
    int recurring;
    int budgets = 0;
    double initialBalance = 0;
    if (isAccount) {
      final row = await db.accountById(id);
      if (row == null) return;
      final fallback = await db.fallbackAccount(row.profileId);
      if (fallback == null) throw Exception('Базовый счёт не найден');
      destination = fallback.name;
      initialBalance = row.initialBalance;
      operations =
          (await (db.select(db.transactions)..where(
                    (t) => t.accountId.equals(id) | t.toAccountId.equals(id),
                  ))
                  .get())
              .length;
      recurring = (await (db.select(
        db.recurringPayments,
      )..where((r) => r.accountId.equals(id))).get()).length;
    } else {
      final row = await db.categoryById(id);
      if (row == null) return;
      final fallback = await db.fallbackCategory(row.type, row.profileId);
      if (fallback == null) throw Exception('Базовая категория не найдена');
      destination = fallback.name;
      operations = (await (db.select(
        db.transactions,
      )..where((t) => t.categoryId.equals(id))).get()).length;
      recurring = (await (db.select(
        db.recurringPayments,
      )..where((r) => r.categoryId.equals(id))).get()).length;
      budgets =
          (await (db.select(db.budgetCategories)
                    ..where((b) => b.categoryId.equals(id))
                    ..orderBy([(b) => OrderingTerm(expression: b.budgetId)]))
                  .get())
              .length;
    }
    if (!context.mounted) return;
    final details = <String>[
      'Удалить «$name» без возможности восстановления?',
      if (operations > 0)
        'Операции ($operations) будут перенесены ${isAccount ? 'на счёт' : 'в категорию'} «$destination». Это изменит историю и может повлиять на отчёты.'
      else
        'Операций нет — перенос истории не требуется.',
      if (recurring > 0)
        'Регулярные платежи ($recurring) будут привязаны к «$destination».',
      if (budgets > 0)
        'Категория будет исключена из бюджетов ($budgets), что изменит их расчёты.',
      if (initialBalance != 0)
        'Начальный баланс удаляемого счёта будет удалён. Общий баланс изменится.',
      'Рекомендуем сначала экспортировать данные. Чтобы сохранить историю без изменений, используйте архивацию.',
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAccount ? 'Удалить счёт?' : 'Удалить категорию?'),
        content: SingleChildScrollView(child: Text(details.join('\n\n'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'export'),
            child: const Text('Экспортировать'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (result == 'delete') await onDelete();
    if (result == 'export' && context.mounted) {
      final profiles = context.read<ProfileCubit>();
      await showDialog<void>(
        context: context,
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>.value(value: profiles),
            BlocProvider<ExportCubit>(create: (_) => getIt<ExportCubit>()),
          ],
          child: const ExportDialog(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Архивация и удаление',
    onSelected: (action) async {
      try {
        if (action == 'delete') {
          await _delete(context);
        } else {
          await onArchiveChanged(!isArchived);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArchived
                      ? '«$name» восстановлен из архива'
                      : '«$name» в архиве. История и отчёты сохранены.',
                ),
              ),
            );
          }
        }
      } catch (error) {
        showAppError(error);
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'archive',
        child: Text(isArchived ? 'Восстановить' : 'Архивировать'),
      ),
      const PopupMenuItem(value: 'delete', child: Text('Удалить навсегда')),
    ],
  );
}
