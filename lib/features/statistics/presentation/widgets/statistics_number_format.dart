import '../../../shared/utils/money_format.dart';

/// A decimal number with a Russian separator and no trailing fractional zeros.
String formatStatisticNumber(double value, {int decimals = 1}) {
  var text = value.toStringAsFixed(decimals);
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  if (text == '-0') text = '0';
  return text.replaceAll('.', ',');
}

/// A chart total without currency; small totals retain their full value.
String formatStatisticTotal(double value) {
  final amount = value.abs();
  if (amount >= 1000000000) {
    return '${formatStatisticNumber(amount / 1000000000, decimals: 2)} млрд';
  }
  if (amount >= 1000000) {
    return '${formatStatisticNumber(amount / 1000000, decimals: 2)} млн';
  }
  final parts = formatStatisticNumber(amount, decimals: 2).split(',');
  final integer = parts.first;
  final grouped = StringBuffer();
  for (var index = 0; index < integer.length; index++) {
    if (index > 0 && (integer.length - index) % 3 == 0) {
      grouped.write('\u00a0');
    }
    grouped.write(integer[index]);
  }
  if (parts.length > 1) grouped.write(',${parts.last}');
  return grouped.toString();
}

/// Compact legend money; exact smaller amounts keep the shared money format.
String formatCompactStatisticMoney(double value) {
  final amount = value.abs();
  if (amount >= 1000000000) {
    return '${formatStatisticNumber(amount / 1000000000, decimals: 2)} млрд\u00a0₽';
  }
  if (amount >= 1000000) {
    return '${formatStatisticNumber(amount / 1000000, decimals: 2)} млн\u00a0₽';
  }
  if (amount >= 10000) {
    return '${formatStatisticNumber(amount / 1000, decimals: 2)} тыс.\u00a0₽';
  }
  return formatMoneyAbs(amount);
}
