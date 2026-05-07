import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/enums/transaction_type.dart';

class TransactionTypeFilterStorage {
  TransactionTypeFilterStorage(this._preferences);

  static const _key = 'transactions.visibleTypes';

  final SharedPreferences _preferences;

  Set<TransactionType> read() {
    final stored = _preferences.getStringList(_key);
    if (stored == null) {
      return TransactionType.values.toSet();
    }
    final parsed = stored
        .map((name) {
          for (final type in TransactionType.values) {
            if (type.name == name) return type;
          }
          return null;
        })
        .whereType<TransactionType>()
        .toSet();
    if (parsed.isEmpty) {
      return TransactionType.values.toSet();
    }
    return parsed;
  }

  Future<void> write(Set<TransactionType> types) async {
    await _preferences.setStringList(
      _key,
      types.map((type) => type.name).toList(),
    );
  }
}
