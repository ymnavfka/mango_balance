import '../../features/accounts/domain/entities/account.dart';
import '../../features/categories/domain/entities/category.dart';
import '../../features/transactions/domain/entities/transaction.dart';

class PopularityRanker {
  PopularityRanker({
    required List<TransactionEntity> transactions,
    this.recentWindow = 100,
  }) {
    final recent = transactions.length <= recentWindow
        ? transactions
        : transactions.sublist(0, recentWindow);

    _accumulateAccountCounts(transactions, _accountAllTimeCount);
    _accumulateAccountCounts(recent, _accountRecentCount);
    _accumulateCategoryCounts(transactions, _categoryAllTimeCount);
    _accumulateCategoryCounts(recent, _categoryRecentCount);
  }

  final int recentWindow;

  final Map<int, int> _accountRecentCount = {};
  final Map<int, int> _accountAllTimeCount = {};
  final Map<int, int> _categoryRecentCount = {};
  final Map<int, int> _categoryAllTimeCount = {};

  void _accumulateAccountCounts(
    List<TransactionEntity> source,
    Map<int, int> target,
  ) {
    for (final tx in source) {
      final ids = <int>{tx.accountId};
      final toId = tx.toAccountId;
      if (toId != null) ids.add(toId);
      for (final id in ids) {
        target[id] = (target[id] ?? 0) + 1;
      }
    }
  }

  void _accumulateCategoryCounts(
    List<TransactionEntity> source,
    Map<int, int> target,
  ) {
    for (final tx in source) {
      target[tx.categoryId] = (target[tx.categoryId] ?? 0) + 1;
    }
  }

  List<AccountEntity> sortAccounts(Iterable<AccountEntity> accounts) {
    final sorted = accounts.toList();
    sorted.sort(
      (a, b) => _compare(
        _accountRecentCount[a.id] ?? 0,
        _accountRecentCount[b.id] ?? 0,
        _accountAllTimeCount[a.id] ?? 0,
        _accountAllTimeCount[b.id] ?? 0,
        a.id,
        b.id,
      ),
    );
    return sorted;
  }

  List<CategoryEntity> sortCategories(Iterable<CategoryEntity> categories) {
    final sorted = categories.toList();
    sorted.sort(
      (a, b) => _compare(
        _categoryRecentCount[a.id] ?? 0,
        _categoryRecentCount[b.id] ?? 0,
        _categoryAllTimeCount[a.id] ?? 0,
        _categoryAllTimeCount[b.id] ?? 0,
        a.id,
        b.id,
      ),
    );
    return sorted;
  }

  int _compare(int recentA, int recentB, int allA, int allB, int idA, int idB) {
    if (recentA != recentB) return recentB.compareTo(recentA);
    if (allA != allB) return allB.compareTo(allA);
    return idB.compareTo(idA);
  }
}
