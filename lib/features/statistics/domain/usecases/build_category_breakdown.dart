import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/category_breakdown.dart';

class BuildCategoryBreakdown {
  static const int _maxVisibleCategories = 6;

  List<CategoryBreakdown> call({
    required List<TransactionEntity> transactions,
    required TransactionType type,
  }) {
    if (type == TransactionType.transfer) {
      return const [];
    }

    final filtered = transactions.where((tx) => tx.type == type);
    final totalsByCategory = <int, double>{};
    final namesByCategory = <int, String>{};

    for (final tx in filtered) {
      totalsByCategory.update(
        tx.categoryId,
        (existing) => existing + tx.amount.value,
        ifAbsent: () => tx.amount.value,
      );
      namesByCategory.putIfAbsent(tx.categoryId, () => tx.categoryName);
    }

    if (totalsByCategory.isEmpty) {
      return const [];
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    if (total <= 0) {
      return const [];
    }

    final visible = entries.take(_maxVisibleCategories).toList();
    final hidden = entries.skip(_maxVisibleCategories).toList();

    final result = visible.map((entry) {
      return CategoryBreakdown(
        categoryId: entry.key,
        categoryName: namesByCategory[entry.key] ?? '',
        amount: entry.value,
        share: entry.value / total,
      );
    }).toList();

    if (hidden.isNotEmpty) {
      final otherAmount = hidden.fold<double>(
        0,
        (sum, entry) => sum + entry.value,
      );
      result.add(
        CategoryBreakdown(
          categoryId: null,
          categoryName: 'Другое',
          amount: otherAmount,
          share: otherAmount / total,
        ),
      );
    }

    return result;
  }
}
