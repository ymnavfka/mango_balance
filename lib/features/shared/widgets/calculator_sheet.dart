import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Символы операторов (единые для отображения и вычислений).
const String _divide = '÷'; // ÷
const String _multiply = '×'; // ×
const String _minus = '−'; // −
const String _plus = '+';

/// Округление до копеек — приложение работает с деньгами.
double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Значение для записи в поле «Сумма»: чистое число с запятой, без разделителей
/// разрядов, чтобы форма могла его распарсить. Знак «минус» — ASCII, чтобы
/// [double.tryParse] его понимал.
String formatAmountForField(double value) {
  final r = _round2(value);
  var s = r.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  if (s.isEmpty || s == '-') s = '0';
  return s.replaceAll('.', ',');
}

/// Модальный калькулятор для ввода суммы.
///
/// При каждом изменении результата вызывает [onChanged], поэтому поле «Сумма»
/// всегда содержит актуальный результат — даже если закрыть калькулятор, не
/// нажимая «=».
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  /// Текущее значение поля, с которого открывается калькулятор.
  final double? initialValue;

  /// Вызывается на каждое обновление результата вычислений.
  final ValueChanged<double> onChanged;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  /// Операнды выражения (десятичный разделитель — точка). Последний элемент —
  /// число, которое сейчас редактируется; может быть пустым сразу после ввода
  /// оператора. Инвариант: _operands.length == _operators.length + 1.
  List<String> _operands = [''];

  /// Операторы между операндами (символы _plus/_minus/_multiply/_divide).
  List<String> _operators = [];

  /// true, если следующая цифра начинает новое число (после «=» или при старте
  /// с готовым значением из поля).
  bool _startFresh = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null && initial.isFinite) {
      _operands = [_plainNumber(initial)];
      _startFresh = true;
    }
  }

  int get _last => _operands.length - 1;

  /// Вычисление всего выражения с приоритетом операций (× и ÷ раньше + и −).
  /// Незавершённый последний операнд и висящий оператор игнорируются.
  double _evaluate() {
    final nums = <double>[];
    final ops = <String>[];
    for (var i = 0; i < _operands.length; i++) {
      final s = _operands[i];
      if (s.isEmpty) break; // пустым может быть только последний операнд
      nums.add(double.tryParse(s) ?? 0);
      if (i < _operators.length) ops.add(_operators[i]);
    }
    // Отбросить висящий оператор без правого операнда.
    while (ops.isNotEmpty && ops.length >= nums.length) {
      ops.removeLast();
    }
    if (nums.isEmpty) return 0;

    // Первый проход: свернуть × и ÷ слева направо.
    final values = <double>[nums.first];
    final addSub = <String>[];
    for (var i = 0; i < ops.length; i++) {
      final next = nums[i + 1];
      switch (ops[i]) {
        case _multiply:
          values[values.length - 1] = values.last * next;
        case _divide:
          values[values.length - 1] = values.last / next;
        default:
          addSub.add(ops[i]);
          values.add(next);
      }
    }
    // Второй проход: + и − слева направо.
    var result = values.first;
    for (var i = 0; i < addSub.length; i++) {
      result = addSub[i] == _plus
          ? result + values[i + 1]
          : result - values[i + 1];
    }
    return result;
  }

  /// Чистое строковое представление числа (разделитель — точка, без хвостовых
  /// нулей) для хранения результата как операнда.
  String _plainNumber(double value) {
    var s = _round2(value).toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.isEmpty || s == '-' ? '0' : s;
  }

  /// Сообщить форме актуальный результат (если он корректен).
  void _emit() {
    final r = _evaluate();
    if (r.isFinite) widget.onChanged(r);
  }

  void _inputDigit(String d) {
    setState(() {
      if (_startFresh) {
        _operands[_last] = '';
        _startFresh = false;
      }
      final cur = _operands[_last];
      if (cur == '0') {
        _operands[_last] = d == '0' ? '0' : d;
      } else {
        _operands[_last] = cur + d;
      }
    });
    _emit();
  }

  void _inputComma() {
    setState(() {
      if (_startFresh) {
        _operands[_last] = '';
        _startFresh = false;
      }
      final cur = _operands[_last];
      if (cur.isEmpty) {
        _operands[_last] = '0.';
      } else if (!cur.contains('.')) {
        _operands[_last] = '$cur.';
      }
    });
    _emit();
  }

  void _setOperator(String op) {
    setState(() {
      _startFresh = false;
      final cur = _operands[_last];
      if (cur.isEmpty) {
        if (_operators.isNotEmpty) {
          // Пользователь меняет только что введённый оператор.
          _operators[_operators.length - 1] = op;
        } else {
          // Оператор в самом начале — считаем левый операнд нулём.
          _operands[_last] = '0';
          _operators.add(op);
          _operands.add('');
        }
      } else {
        _operators.add(op);
        _operands.add('');
      }
    });
    _emit();
  }

  void _equals() {
    final r = _evaluate();
    if (!r.isFinite) return;
    setState(() {
      _operands = [_plainNumber(r)];
      _operators = [];
      _startFresh = true;
    });
    _emit();
  }

  void _backspace() {
    setState(() {
      _startFresh = false;
      final cur = _operands[_last];
      if (cur.isNotEmpty) {
        _operands[_last] = cur.substring(0, cur.length - 1);
      } else if (_operators.isNotEmpty) {
        // Удаляем висящий оператор и возвращаемся к правке прошлого числа.
        _operators.removeLast();
        _operands.removeLast();
      }
    });
    _emit();
  }

  void _clear() {
    setState(() {
      _operands = [''];
      _operators = [];
      _startFresh = false;
    });
    _emit();
  }

  /// Группировка разрядов неразрывным пробелом (как в остальном приложении).
  String _groupInt(String digits) {
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Форматирование результата: разряды через пробел, дробная часть — запятая,
  /// хвостовые нули убираются.
  String _formatResult(double value) {
    final neg = value < 0;
    var s = _round2(value.abs()).toStringAsFixed(2);
    final dot = s.indexOf('.');
    final intPart = _groupInt(s.substring(0, dot));
    final fracPart = s.substring(dot + 1).replaceAll(RegExp(r'0+$'), '');
    final body = fracPart.isEmpty ? intPart : '$intPart,$fracPart';
    return neg ? '$_minus$body' : body;
  }

  /// Отображение операнда «как есть» (с хвостовой запятой и нулями).
  String _formatOperand(String operand) {
    final dot = operand.indexOf('.');
    if (dot < 0) {
      return _groupInt(operand.isEmpty ? '0' : operand);
    }
    final intPart = _groupInt(
      operand.substring(0, dot).isEmpty ? '0' : operand.substring(0, dot),
    );
    return '$intPart,${operand.substring(dot + 1)}';
  }

  /// Строка всего выражения (мелкая, сверху). Пустая, если операции ещё нет.
  String get _expression {
    if (_operators.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < _operands.length; i++) {
      final s = _operands[i];
      if (i == _last && s.isEmpty) break; // висящий оператор без операнда
      buffer.write(_formatOperand(s));
      if (i < _operators.length) buffer.write(' ${_operators[i]} ');
    }
    return buffer.toString().trimRight();
  }

  /// Крупная строка результата.
  String get _display {
    final r = _evaluate();
    if (!r.isFinite) return 'Ошибка';
    if (_operators.isEmpty) {
      return _formatOperand(_operands[0].isEmpty ? '0' : _operands[0]);
    }
    return _formatResult(r);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(26) / 26;
    // Минимум 48 px для нажатия + 10 px отступов в каждом ряду.
    // На низком экране прокручиваем клавиатуру, а не сжимаем кнопки.
    final keyHeight = 58.0 + (scale - 1).clamp(0, 3) * 36;
    final minimumHeight = 150.0 + (scale - 1).clamp(0, 3) * 70 + keyHeight * 5;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final preferred = media.size.height * 0.62;
          final height = preferred
              .clamp(
                minimumHeight.clamp(0, constraints.maxHeight),
                constraints.maxHeight,
              )
              .toDouble();
          return SizedBox(
            height: height,
            child: SingleChildScrollView(
              child: SizedBox(
                height: height < minimumHeight ? minimumHeight : height,
                child: Column(
                  children: [
                    _header(context),
                    _displayArea(),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(child: _keypad()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.md, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Калькулятор',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  Widget _displayArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(16) * 1.375,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _expression,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _display,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _key('C', onTap: _clear, kind: _KeyKind.clear, flex: 2),
                _key(
                  '',
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                  kind: _KeyKind.back,
                ),
                _key(
                  _divide,
                  onTap: () => _setOperator(_divide),
                  kind: _KeyKind.op,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _key('7', onTap: () => _inputDigit('7')),
                _key('8', onTap: () => _inputDigit('8')),
                _key('9', onTap: () => _inputDigit('9')),
                _key(
                  _multiply,
                  onTap: () => _setOperator(_multiply),
                  kind: _KeyKind.op,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _key('4', onTap: () => _inputDigit('4')),
                _key('5', onTap: () => _inputDigit('5')),
                _key('6', onTap: () => _inputDigit('6')),
                _key(
                  _minus,
                  onTap: () => _setOperator(_minus),
                  kind: _KeyKind.op,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _key('1', onTap: () => _inputDigit('1')),
                _key('2', onTap: () => _inputDigit('2')),
                _key('3', onTap: () => _inputDigit('3')),
                _key(
                  _plus,
                  onTap: () => _setOperator(_plus),
                  kind: _KeyKind.op,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _key('0', onTap: () => _inputDigit('0'), flex: 2),
                _key(',', onTap: _inputComma),
                _key('=', onTap: _equals, kind: _KeyKind.equals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _key(
    String label, {
    IconData? icon,
    required VoidCallback onTap,
    _KeyKind kind = _KeyKind.digit,
    int flex = 1,
  }) {
    late final Color bg;
    late final Color fg;
    switch (kind) {
      case _KeyKind.digit:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textPrimary;
      case _KeyKind.op:
        bg = AppColors.brandContainer;
        fg = AppColors.brand;
      case _KeyKind.equals:
        bg = AppColors.brand;
        fg = Colors.white;
      case _KeyKind.clear:
        bg = AppColors.expenseSurface;
        fg = AppColors.expense;
      case _KeyKind.back:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textSecondary;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs + 1),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: fg, size: 24)
                  : Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyKind { digit, op, equals, clear, back }
