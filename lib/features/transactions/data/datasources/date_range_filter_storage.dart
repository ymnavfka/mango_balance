import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DateRangeFilterStorage {
  DateRangeFilterStorage(this._preferences);

  static const _startKey = 'transactions.dateRangeStart';
  static const _endKey = 'transactions.dateRangeEnd';

  final SharedPreferences _preferences;

  DateTimeRange? read() {
    final start = _preferences.getInt(_startKey);
    final end = _preferences.getInt(_endKey);
    if (start == null || end == null) return null;
    return DateTimeRange(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
    );
  }

  Future<void> write(DateTimeRange? range) async {
    if (range == null) {
      await _preferences.remove(_startKey);
      await _preferences.remove(_endKey);
      return;
    }
    await _preferences.setInt(_startKey, range.start.millisecondsSinceEpoch);
    await _preferences.setInt(_endKey, range.end.millisecondsSinceEpoch);
  }
}
