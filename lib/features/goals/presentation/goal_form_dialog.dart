import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/app_error_notifier.dart';
import '../../accounts/presentation/cubit/account_cubit.dart';
import '../../recurring/domain/entities/recurring_payment.dart';
import '../../recurring/domain/entities/recurring_interval.dart';
import '../../shared/widgets/app_dialog.dart';
import '../domain/goal.dart';
import 'goal_cubit.dart';

class GoalFormDialog extends StatefulWidget {
  const GoalFormDialog({super.key, this.initial, this.source});
  final GoalPlan? initial;
  final RecurringPaymentEntity? source;
  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  late final TextEditingController _name, _target, _count;
  late DateTime _date;
  String? _unit;
  int? _account;
  bool _busy = false, _resume = false;
  @override
  void initState() {
    super.initState();
    final goal = widget.initial;
    final source = widget.source;
    _name = TextEditingController(text: goal?.name ?? source?.name ?? '');
    _target = TextEditingController(
      text: goal != null
          ? (goal.target / 100).toString()
          : source?.amount.toString() ?? '',
    );
    _count = TextEditingController(
      text: '${goal?.intervalCount ?? source?.intervalCount ?? 1}',
    );
    _date = goal?.dueDate ?? source?.nextRunDate ?? goalDay(DateTime.now());
    _unit = goal?.intervalUnit ?? source?.intervalUnit.storageKey;
    _account = goal?.accountId ?? source?.accountId;
  }

  @override
  void dispose() {
    for (final c in [_name, _target, _count]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _money(String value) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number.abs() > 9000000000000) {
      return null;
    }
    return (number * 100).round();
  }

  Future<void> _save() async {
    final target = _money(_target.text), count = int.tryParse(_count.text);
    if (_name.text.trim().isEmpty ||
        target == null ||
        target <= 0 ||
        _account == null ||
        (_unit != null && (count == null || count < 1 || count > 10000))) {
      showAppNotice('Укажите название, сумму, счёт и корректный период');
      return;
    }
    setState(() => _busy = true);
    final initial = widget.initial;
    final cubit = context.read<GoalCubit>();
    try {
      await cubit.save(
        GoalPlan(
          id: initial?.id ?? 0,
          profileId: initial?.profileId ?? cubit.profile.id,
          name: _name.text,
          target: target,
          dueDate: _date,
          anchorDate:
              initial != null &&
                  _date == initial.dueDate &&
                  _unit == initial.intervalUnit &&
                  count == initial.intervalCount
              ? initial.anchorDate
              : _date,
          intervalUnit: _unit,
          intervalCount: _unit == null ? 1 : count!,
          accountId: _account,
          status: initial == null || _resume ? 'active' : initial.status,
          savedSnapshot: initial?.savedSnapshot ?? 0,
          savedOccurrenceCount: initial?.savedOccurrenceCount ?? 0,
          savedThroughDate: initial?.savedThroughDate,
          sourcePaymentId: initial?.sourcePaymentId ?? widget.source?.id,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      showAppError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context
        .watch<AccountCubit>()
        .state
        .accounts
        .where((a) => !a.isArchived)
        .toList();
    // Keep an unavailable account visible as an error; never switch funds.
    final validAccount = accounts.any((a) => a.id == _account);
    return AppDialog(
      title: widget.initial == null ? 'Новая цель' : 'Редактирование цели',
      primaryLabel: 'Сохранить',
      onPrimary: _busy || !validAccount ? null : _save,
      loading: _busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Нужно накопить, ₽'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              'К ${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
            ),
            onPressed: () async {
              final today = goalDay(DateTime.now());
              final date = await showDatePicker(
                context: context,
                initialDate: _date.isBefore(today) ? today : _date,
                firstDate: today,
                lastDate: DateTime(9999),
              );
              if (date != null && mounted) setState(() => _date = date);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _unit ?? 'none',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Повторение'),
            items: [
              const DropdownMenuItem(value: 'none', child: Text('Без повтора')),
              ...RecurringInterval.values.map(
                (u) => DropdownMenuItem(
                  value: u.storageKey,
                  child: Text(u.singularLabel),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _unit = v == 'none' ? null : v),
          ),
          if (_unit != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Каждые N единиц периода',
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: validAccount ? _account : null,
            hint: Text(
              accounts.isEmpty ? 'Сначала создайте счёт' : 'Выберите счёт',
            ),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Счёт для накоплений'),
            items: accounts
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _account = v),
          ),
          const SizedBox(height: 12),
          if (_account != null && !validAccount)
            const Text('Счёт отключён. Выберите другой счёт для цели.')
          else if (accounts.isEmpty)
            const Text('Для создания цели сначала добавьте счёт.')
          else
            const Text(
              'Деньги счёта идут на будущие события по порядку дат. В одну дату делятся поровну.',
            ),
          if (widget.initial?.status == 'paused')
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Цель на паузе. Выберите счёт и включите «Возобновить», чтобы продолжить.',
              ),
            ),
          if (widget.initial != null && !widget.initial!.isActive)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Возобновить цель'),
              subtitle: const Text('Проверьте срок и текущие накопления'),
              value: _resume,
              onChanged: (v) => setState(() => _resume = v),
            ),
          if (widget.source != null || widget.initial?.sourcePaymentId != null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Создано из регулярного платежа. Изменения платежа и цели независимы.',
              ),
            ),
        ],
      ),
    );
  }
}
