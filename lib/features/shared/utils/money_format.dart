/// Форматирование денежных сумм в едином стиле по всему приложению.
///
/// Используется русский формат: разряды разделены неразрывным пробелом,
/// дробная часть — запятой, в конце символ рубля.
library;

String _grouped(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(intPart[i]);
  }
  return '${buffer.toString()},${parts[1]} ₽';
}

/// Сумма со знаком только для отрицательных значений (для балансов).
String formatMoney(double value) {
  final sign = value < 0 ? '−' : '';
  return '$sign${_grouped(value)}';
}

/// Модуль суммы без знака (знак добавляется отдельно по типу операции).
String formatMoneyAbs(double value) => _grouped(value);
