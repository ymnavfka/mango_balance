import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/net_worth_history.dart';
import '../../domain/entities/net_worth_point.dart';
import 'net_worth_plot.dart';

enum _CapitalPeriod {
  week('7 д', 7),
  month('Месяц', 30),
  quarter('3 мес', 90),
  year('Год', 365),
  all('Всё', null);

  const _CapitalPeriod(this.label, this.days);
  final String label;
  final int? days;
}

/// Capital has its own explicitly labelled period, separate from cash flow.
class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({super.key, required this.points});

  final List<NetWorthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(18),
      child: _CapitalContent(points: points),
    );
  }
}

class _CapitalContent extends StatefulWidget {
  const _CapitalContent({
    required this.points,
    this.detail = false,
    this.initialPeriod = _CapitalPeriod.month,
    this.initialDay,
  });

  final List<NetWorthPoint> points;
  final bool detail;
  final _CapitalPeriod initialPeriod;
  final int? initialDay;

  @override
  State<_CapitalContent> createState() => _CapitalContentState();
}

class _CapitalContentState extends State<_CapitalContent> {
  late NetWorthHistory _history;
  late _CapitalPeriod _period;
  int? _selected;
  int? _hover;

  int get _end => _history.lastDay;
  int get _start => _period.days == null
      ? _history.firstDay
      : math.max(_history.firstDay, _end - _period.days! + 1);
  int get _day => _hover ?? _selected ?? _end;
  bool get _inspecting => _hover != null || _selected != null;

  @override
  void initState() {
    super.initState();
    _history = NetWorthHistory(widget.points);
    _period = widget.initialPeriod;
    _selected = widget.initialDay ?? (widget.detail ? _end : null);
    _selected = _selected?.clamp(_start, _end);
  }

  @override
  void didUpdateWidget(covariant _CapitalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _history = NetWorthHistory(widget.points);
    _selected = _selected?.clamp(_start, _end);
    _hover = null;
  }

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  String _date(int day) {
    final date = NetWorthHistory.dateForDay(day);
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _signed(double value) =>
      '${value > 0 ? '+' : ''}${formatMoney(value)}';

  void _select(int day) {
    if (_selected == day && _hover == null) return;
    setState(() {
      _selected = day.clamp(_start, _end);
      _hover = null;
    });
  }

  void _changePeriod(_CapitalPeriod period) {
    setState(() {
      _period = period;
      _hover = null;
      _selected = widget.detail
          ? (_selected ?? _end).clamp(_start, _end)
          : null;
    });
  }

  Future<void> _pickDay() async {
    final date = await showDatePicker(
      context: context,
      initialDate: NetWorthHistory.dateForDay(_day),
      firstDate: NetWorthHistory.dateForDay(_start),
      lastDate: NetWorthHistory.dateForDay(_end),
      helpText: 'Баланс на дату',
    );
    if (date != null && mounted) _select(NetWorthHistory.dayNumber(date));
  }

  void _openDetail() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Капитал')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: _CapitalContent(
                        points: widget.points,
                        detail: true,
                        initialPeriod: _period,
                        initialDay: _day,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final balance = _history.balanceAt(_day);
    final opening = _history.openingBalance(widget.detail ? _day : _start);
    final difference = ((balance - opening) * 100).round() / 100;
    final today = _day == NetWorthHistory.dayNumber(DateTime.now());
    final caption = today
        ? 'Сегодня · текущий баланс'
        : '${_date(_day)} · на конец дня';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Капитал', style: text.titleMedium),
            Text(
              'Все счета · ₽',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          caption,
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: 'Баланс',
          child: Text(
            formatMoney(balance),
            key: const ValueKey('net-worth-balance'),
            style: text.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_signed(difference)} ${widget.detail
              ? 'за день'
              : _inspecting
              ? 'с начала периода'
              : 'за период'}',
          key: const ValueKey('net-worth-change'),
          style: text.bodyMedium?.copyWith(color: AppColors.amount(difference)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Период капитала',
          style: text.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
            final narrow = constraints.maxWidth < 340 || largeText;
            // Wrap at phone widths / large text instead of clipping a segment.
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _CapitalPeriod.values
                  .map(
                    (period) => ChoiceChip(
                      label: Text(period.label),
                      selected: period == _period,
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 6 : 10,
                        vertical: 6,
                      ),
                      onSelected: (_) => _changePeriod(period),
                      tooltip: switch (period) {
                        _CapitalPeriod.week => 'Последние 7 дней',
                        _CapitalPeriod.month => 'Последние 30 дней',
                        _CapitalPeriod.quarter => 'Последние 90 дней',
                        _CapitalPeriod.year => 'Последние 365 дней',
                        _CapitalPeriod.all => 'Вся история',
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_date(_start)} — ${_date(_end)}',
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        NetWorthPlot(
          history: _history,
          start: _start,
          end: _end,
          selected: _inspecting ? _day : null,
          semanticValue: '${_date(_day)}, ${formatMoney(balance)}',
          onSelect: _select,
          onHover: (day) {
            if (_hover != day) setState(() => _hover = day);
          },
        ),
        if (widget.detail) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: 'Предыдущий день',
                onPressed: _day > _start ? () => _select(_day - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _pickDay,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_date(_day), textAlign: TextAlign.center),
                ),
              ),
              IconButton(
                tooltip: 'Следующий день',
                onPressed: _day < _end ? () => _select(_day + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: _hover == null,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _BalanceRow(
                    label: 'На начало дня',
                    value: formatMoney(_history.openingBalance(_day)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BalanceRow(
                    label: difference.abs() < .005
                        ? 'Без изменений'
                        : 'Изменение за день',
                    value: _signed(difference),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(),
                  ),
                  _BalanceRow(
                    label: today ? 'Сейчас' : 'На конец дня',
                    value: formatMoney(balance),
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _openDetail,
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text('Точный просмотр'),
              ),
              if (_selected != null)
                TextButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _hover = null;
                  }),
                  child: const Text('К последнему дню'),
                )
              else
                Text(
                  'Нажмите или проведите по графику',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = emphasized ? text.titleSmall : text.bodyMedium;
        if (constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: style),
              ],
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value, style: style, textAlign: TextAlign.end),
            ),
          ],
        );
      },
    );
  }
}
