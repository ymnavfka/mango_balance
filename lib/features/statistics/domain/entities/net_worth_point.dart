/// Точка графика капитала: накопленный баланс на конец дня [date].
class NetWorthPoint {
  const NetWorthPoint({required this.date, required this.balance});

  final DateTime date;
  final double balance;
}
