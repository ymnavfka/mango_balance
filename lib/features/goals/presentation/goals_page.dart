import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/app_error_notifier.dart';
import '../../recurring/presentation/cubit/recurring_cubit.dart';
import '../../recurring/presentation/widgets/recurring_payment_form_dialog.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/money_format.dart';
import '../../shared/widgets/app_drawer.dart';
import '../domain/goal.dart';
import 'goal_cubit.dart';
import 'goal_form_dialog.dart';

const _periodLabels = ['День', 'Неделя', 'Месяц', 'Год'];
const _periodFactors = [1.0, 7.0, 365.2425 / 12, 365.2425];
String _money(num cents) => formatMoney(cents / 100);
String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
GoalCoverage _coverage(GoalSnapshot snapshot, GoalPlan goal) =>
    snapshot.coverage[goal.id] ??
    GoalCoverage(firstEventDate: goal.dueDate, nextUncoveredDate: goal.dueDate);

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  int _period = 0;
  String _filter = 'active';
  int? _focused;
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _focused = ModalRoute.of(context)?.settings.arguments as int?;
      _initialized = true;
    }
  }

  void _form({GoalPlan? goal}) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => GoalFormDialog(initial: goal),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Цели')),
    drawer: const AppDrawer(currentRoute: AppRoute.goals),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _form(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Цель'),
    ),
    body: SafeArea(
      top: false,
      child: BlocBuilder<GoalCubit, GoalSnapshot>(
        builder: (context, snapshot) {
          final visible =
              snapshot.goals
                  .where(
                    (g) => _focused != null
                        ? g.id == _focused
                        : g.status == _filter,
                  )
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final total = snapshot.goals.fold<double>(
            0,
            (sum, g) =>
                sum + dailyGoalRate(g, _coverage(snapshot, g), DateTime.now()),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < _periodLabels.length; i++)
                    ChoiceChip(
                      label: Text(_periodLabels[i]),
                      selected: _period == i,
                      onSelected: (_) => setState(() => _period = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Откладывать до ближайших непокрытых событий'),
                      const SizedBox(height: 6),
                      Text(
                        '${_money(total * _periodFactors[_period])} / ${_periodLabels[_period].toLowerCase()}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Расчёт учитывает текущие накопления и ближайшее непокрытое событие. Месяц и год считаются по средней продолжительности; будущие доходы не прогнозируются.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_focused != null)
                TextButton(
                  onPressed: () => setState(() => _focused = null),
                  child: const Text('Показать все цели'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final entry in {
                      'active': 'Активные',
                      'paused': 'Приостановленные',
                      'completed': 'Завершённые',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: (_) => setState(() => _filter = entry.key),
                      ),
                  ],
                ),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    'Здесь пока нет целей. Создайте цель или выберите другой список.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final goal in visible) _card(context, goal, snapshot),
            ],
          );
        },
      ),
    ),
  );
  Widget _card(BuildContext context, GoalPlan goal, GoalSnapshot snapshot) {
    final coverage = _coverage(snapshot, goal);
    final saved = goal.isActive
        ? coverage.firstEventAllocated
        : goal.savedSnapshot;
    final rate =
        dailyGoalRate(goal, coverage, DateTime.now()) * _periodFactors[_period];
    final totalAllocated = goal.isActive
        ? coverage.allocated
        : goal.savedSnapshot;
    final occurrenceCount = goal.isActive
        ? coverage.coveredOccurrences
        : goal.savedOccurrenceCount;
    final coveredThrough = goal.isActive
        ? coverage.coveredThrough
        : goal.savedThroughDate;
    final accountGoals = goal.accountId == null
        ? 0
        : snapshot.goals
              .where((g) => g.isActive && g.accountId == goal.accountId)
              .length;
    final partialText = goal.isActive && coverage.nextUncoveredDate != null
        ? 'На ${goal.intervalUnit == null ? 'цель' : 'следующее событие'} ${_date(coverage.nextUncoveredDate!)} выделено ${_money(coverage.nextUncoveredAllocated)} из ${_money(goal.target)}'
        : null;
    final status = !goal.isActive
        ? goal.status == 'paused'
              ? 'Приостановлена'
              : 'Завершена'
        : goal.intervalUnit == null && saved >= goal.target
        ? 'Накоплено'
        : calendarDays(DateTime.now(), goal.dueDate) == 0
        ? 'Срок сегодня'
        : 'Ближайшее событие: ${_money(goal.target)}';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') {
                      _form(goal: goal);
                      return;
                    }
                    final approved = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          action == 'delete'
                              ? 'Удалить цель?'
                              : 'Завершить цель?',
                        ),
                        content: Text(
                          action == 'delete'
                              ? 'Цель будет удалена. Операции и регулярный платёж сохранятся.'
                              : 'Цель перестанет участвовать в распределении. Деньги со счёта не списываются.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Подтвердить'),
                          ),
                        ],
                      ),
                    );
                    if (approved != true || !context.mounted) return;
                    try {
                      final cubit = context.read<GoalCubit>();
                      if (action == 'delete') {
                        await cubit.delete(goal.id);
                      } else {
                        await cubit.complete(goal.id);
                      }
                    } catch (error) {
                      showAppError(error);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Редактировать'),
                    ),
                    if (goal.isActive)
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('Завершить'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Ближайшая дата: ${_date(goal.dueDate)}${goal.intervalUnit == null ? ' · Одноразовая' : ' · Повторяется'}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.target > 0 ? (saved / goal.target).clamp(0, 1) : 0,
              color: AppColors.brand,
            ),
            const SizedBox(height: 8),
            Text(
              '${_money(saved)} из ${_money(goal.target)} на ближайшее событие · $status',
            ),
            if (goal.isActive && goal.intervalUnit != null) ...[
              const SizedBox(height: 8),
              Text(
                occurrenceCount == 0
                    ? 'Пока не покрыто полностью ни одного повтора'
                    : 'Полностью покрыто повторений: $occurrenceCount${coveredThrough == null ? '' : ' · до ${_date(coveredThrough)}'}',
              ),
            ],
            if (partialText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(partialText),
              ),
            if (goal.isActive) ...[
              const SizedBox(height: 8),
              Text(
                'Откладывать ${_money(rate)} / ${_periodLabels[_period].toLowerCase()} до следующего непокрытого события',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (goal.isActive && goal.accountId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${snapshot.accountNames[goal.accountId] ?? 'Счёт'}: по календарю учтено ${_money(totalAllocated)} из ${_money(snapshot.balances[goal.accountId] ?? 0)} на счёте · активных целей: $accountGoals',
                ),
              ),
            if (!goal.isActive && occurrenceCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'На момент завершения было покрыто $occurrenceCount событий${coveredThrough == null ? '' : ' · до ${_date(coveredThrough)}'}.',
                ),
              ),
            if (goal.status == 'paused')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Счёт отключён. Последний прогресс сохранён для справки. Отредактируйте цель, выберите доступный счёт и включите «Возобновить».',
                ),
              ),
            if (goal.sourcePaymentId != null)
              TextButton(
                onPressed: () {
                  final recurring = context.read<RecurringCubit>();
                  final sources = recurring.state.payments.where(
                    (p) => p.id == goal.sourcePaymentId,
                  );
                  if (sources.isEmpty) {
                    showAppNotice('Платёж недоступен');
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (_) => RecurringPaymentFormDialog(
                      initial: sources.first,
                      onSubmit: recurring.updateRecurringPayment,
                    ),
                  );
                },
                child: const Text('Открыть регулярный платёж'),
              ),
          ],
        ),
      ),
    );
  }
}
