import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/net_worth_history.dart';
import '../../domain/entities/net_worth_point.dart';

/// A day-addressable plot: hit testing uses the whole surface, not the line.
class NetWorthPlot extends StatelessWidget {
  const NetWorthPlot({
    super.key,
    required this.history,
    required this.start,
    required this.end,
    required this.selected,
    required this.onSelect,
    required this.onHover,
    required this.semanticValue,
  });

  final NetWorthHistory history;
  final int start;
  final int end;
  final int? selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<int?> onHover;
  final String semanticValue;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final axisStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
    final points = history.window(start, end);
    final scale = _BalanceScale(points);
    final labelWidth = scale.ticks
        .map((value) {
          final painter = TextPainter(
            text: TextSpan(text: scale.label(value), style: axisStyle),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout();
          return painter.width;
        })
        .reduce(math.max);
    final right = math.max(72.0, labelWidth + 16);
    final bottom = math.max(34.0, scaler.scale(28));
    return LayoutBuilder(
      builder: (context, constraints) {
        int dayAt(Offset position) {
          final width = math.max(1.0, constraints.maxWidth - right - 8);
          final fraction = ((position.dx - 8) / width).clamp(0.0, 1.0);
          return start + ((end - start) * fraction).round();
        }

        void move(int delta) =>
            onSelect(((selected ?? end) + delta).clamp(start, end));

        String valueForDay(int day) =>
            '${MaterialLocalizations.of(context).formatFullDate(NetWorthHistory.dateForDay(day))}, '
            '${formatMoney(history.balanceAt(day))}';

        return Semantics(
          label: 'График капитала. Выбор дня',
          value: semanticValue,
          increasedValue: (selected ?? end) < end
              ? valueForDay((selected ?? end) + 1)
              : null,
          decreasedValue: (selected ?? end) > start
              ? valueForDay((selected ?? end) - 1)
              : null,
          onIncrease: (selected ?? end) < end ? () => move(1) : null,
          onDecrease: (selected ?? end) > start ? () => move(-1) : null,
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  move(-1);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  move(1);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              onHover: (event) => onHover(dayAt(event.localPosition)),
              onExit: (_) => onHover(null),
              child: GestureDetector(
                key: const ValueKey('net-worth-plot'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (event) => onSelect(dayAt(event.localPosition)),
                onHorizontalDragStart: (event) =>
                    onSelect(dayAt(event.localPosition)),
                onHorizontalDragUpdate: (event) =>
                    onSelect(dayAt(event.localPosition)),
                onLongPressStart: (event) =>
                    onSelect(dayAt(event.localPosition)),
                onLongPressMoveUpdate: (event) =>
                    onSelect(dayAt(event.localPosition)),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 252 + bottom - 34),
                  painter: _NetWorthPainter(
                    points: points,
                    scale: scale,
                    start: start,
                    end: end,
                    selected: selected,
                    selectedBalance: history.balanceAt(selected ?? end),
                    right: right,
                    bottom: bottom,
                    textScaler: scaler,
                    axisStyle: axisStyle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NetWorthPainter extends CustomPainter {
  _NetWorthPainter({
    required this.points,
    required this.scale,
    required this.start,
    required this.end,
    required this.selected,
    required this.selectedBalance,
    required this.right,
    required this.bottom,
    required this.textScaler,
    required this.axisStyle,
  });

  final List<NetWorthPoint> points;
  final _BalanceScale scale;
  final int start;
  final int end;
  final int? selected;
  final double selectedBalance;
  final double right;
  final double bottom;
  final TextScaler textScaler;
  final TextStyle axisStyle;

  static const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      8,
      20,
      math.max(9, size.width - right),
      size.height - bottom,
    );
    final minY = scale.min;
    final maxY = scale.max;
    double x(int day) => end == start
        ? plot.center.dx
        : plot.left + (day - start) / (end - start) * plot.width;
    double y(double value) =>
        plot.bottom - (value - minY) / (maxY - minY) * plot.height;

    void label(String text, Offset position, {double align = 0}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: axisStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (position.dx - painter.width * align).clamp(
            0.0,
            math.max(0.0, size.width - painter.width),
          ),
          position.dy - painter.height / 2,
        ),
      );
    }

    final grid = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    for (final value in scale.ticks) {
      canvas.drawLine(
        Offset(plot.left, y(value)),
        Offset(plot.right, y(value)),
        grid,
      );
      label(scale.label(value), Offset(plot.right + 10, y(value)));
    }
    if (minY < 0 && maxY > 0) {
      canvas.drawLine(
        Offset(plot.left, y(0)),
        Offset(plot.right, y(0)),
        Paint()
          ..color = AppColors.textTertiary
          ..strokeWidth = 1.2,
      );
    }
    final path = Path()..moveTo(x(start), y(points.first.balance));
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
      path.lineTo(
        x(NetWorthHistory.dayNumber(point.date)),
        y(points[i - 1].balance),
      );
      path.lineTo(x(NetWorthHistory.dayNumber(point.date)), y(point.balance));
    }
    if (end == start) {
      path.reset();
      path.moveTo(plot.left, y(points.first.balance));
      path.lineTo(plot.right, y(points.first.balance));
    }
    final area = Path.from(path)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brand.withValues(alpha: .12),
            AppColors.brand.withValues(alpha: .01),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.brand
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final point = Offset(x(selected ?? end), y(selectedBalance));
    if (selected != null) {
      final guide = Paint()
        ..color = AppColors.textTertiary
        ..strokeWidth = 1;
      for (var top = plot.top; top < plot.bottom; top += 7) {
        canvas.drawLine(
          Offset(point.dx, top),
          Offset(point.dx, math.min(top + 3, plot.bottom)),
          guide,
        );
      }
      for (var left = plot.left; left < plot.right; left += 7) {
        canvas.drawLine(
          Offset(left, point.dy),
          Offset(math.min(left + 3, plot.right), point.dy),
          guide,
        );
      }
    }
    canvas.drawCircle(
      point,
      9,
      Paint()..color = AppColors.brand.withValues(alpha: .12),
    );
    canvas.drawCircle(point, 4.5, Paint()..color = AppColors.brand);
    canvas.drawCircle(
      point,
      4.5,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    String dateLabel(int day) {
      final date = NetWorthHistory.dateForDay(day);
      return end - start > 180
          ? '${months[date.month - 1]} ${date.year % 100}'
          : '${date.day} ${months[date.month - 1]}';
    }

    double labelWidth(int day) => (TextPainter(
      text: TextSpan(text: dateLabel(day), style: axisStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout()).width;

    if (start != end && labelWidth(start) + labelWidth(end) + 12 > plot.width) {
      label(dateLabel(end), Offset(x(end), plot.bottom + bottom / 2), align: 1);
      return;
    }
    label(dateLabel(start), Offset(x(start), plot.bottom + bottom / 2));
    if (start == end) return;
    label(dateLabel(end), Offset(x(end), plot.bottom + bottom / 2), align: 1);
    final firstDate = NetWorthHistory.dateForDay(start);
    final candidates = <int>[];
    if (end - start <= 45) {
      var day = start + (8 - firstDate.weekday) % 7;
      for (; day < end; day += 7) {
        candidates.add(day);
      }
    } else {
      var date = DateTime(firstDate.year, firstDate.month + 1);
      final monthsStep = end - start > 730
          ? 12
          : end - start > 365
          ? 3
          : 1;
      while (NetWorthHistory.dayNumber(date) < end) {
        candidates.add(NetWorthHistory.dayNumber(date));
        date = DateTime(date.year, date.month + monthsStep);
      }
    }
    var occupiedUntil = x(start) + labelWidth(start) + 12;
    final rightLimit = x(end) - labelWidth(end) - 12;
    var interiorCount = 0;
    for (final day in candidates) {
      if (day <= start) continue;
      final halfWidth = labelWidth(day) / 2;
      if (x(day) - halfWidth >= occupiedUntil &&
          x(day) + halfWidth <= rightLimit &&
          interiorCount < 2) {
        label(
          dateLabel(day),
          Offset(x(day), plot.bottom + bottom / 2),
          align: .5,
        );
        occupiedUntil = x(day) + halfWidth + math.max(12, plot.width / 5);
        interiorCount++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetWorthPainter oldDelegate) => true;
}

/// Round ticks with enough precision to distinguish small changes at any scale.
class _BalanceScale {
  _BalanceScale(List<NetWorthPoint> points) {
    final low = points.map((p) => p.balance).reduce(math.min);
    final high = points.map((p) => p.balance).reduce(math.max);
    final spread = high - low;
    final magnitude = math.max(low.abs(), high.abs());
    final padding = spread == 0 ? math.max(magnitude * .03, 1.0) : spread * .1;
    final rawStep = math.max((spread + 2 * padding) / 4, .01);
    final power = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    step =
        [1.0, 2.0, 2.5, 5.0, 10.0].firstWhere((v) => v * power >= rawStep) *
        power;
    min = ((low - padding) / step).floor() * step;
    max = ((high + padding) / step).ceil() * step;

    // Use a single unit across the axis, including zero and negative ticks.
    final extent = math.max(min.abs(), max.abs());
    final unit = extent >= 1e9
        ? (1e9, ' млрд')
        : extent >= 1e6
        ? (1e6, ' млн')
        : extent >= 1e3
        ? (1e3, ' тыс.')
        : (1.0, '');
    divisor = unit.$1;
    suffix = unit.$2;
  }

  late final double min;
  late final double max;
  late final double step;
  late final double divisor;
  late final String suffix;

  Iterable<double> get ticks sync* {
    for (var i = 0; i <= ((max - min) / step).round(); i++) {
      yield min + i * step;
    }
  }

  String label(double value) {
    final precision = math
        .max(0, (math.log(divisor / step) / math.ln10).ceil() + 1)
        .clamp(0, 12);
    var number = (value / divisor).toStringAsFixed(precision);
    if (number.contains('.')) {
      number = number
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    if (number == '-0') number = '0';
    return '${number.replaceAll('.', ',').replaceAll('-', '−')}$suffix';
  }
}
