import 'net_worth_point.dart';

/// Sparse closing balances. Calendar-day arithmetic avoids DST offsets.
class NetWorthHistory {
  NetWorthHistory(this.points) : assert(points.isNotEmpty);

  final List<NetWorthPoint> points;

  static int dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static DateTime dateForDay(int day) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      day * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utc.year, utc.month, utc.day);
  }

  int get firstDay => dayNumber(points.first.date);
  int get lastDay => dayNumber(points.last.date);

  /// Carry the previous closing balance through days without transactions.
  double balanceAt(int day) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (dayNumber(points[middle].date) <= day) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return points[low == 0 ? 0 : low - 1].balance;
  }

  double openingBalance(int day) => balanceAt(day - 1);

  /// Keep the chart sparse even when the history spans many years.
  List<NetWorthPoint> window(int start, int end) => [
    NetWorthPoint(date: dateForDay(start), balance: balanceAt(start)),
    for (final point in points)
      if (dayNumber(point.date) > start && dayNumber(point.date) < end) point,
    if (end > start)
      NetWorthPoint(date: dateForDay(end), balance: balanceAt(end)),
  ];
}
