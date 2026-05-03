import '../../domain/entities/transaction.dart';
import '../cubit/transaction_state.dart';

class TransactionSectionBuilder {
  static List<TransactionSection> buildSections(
    List<TransactionEntity> transactions,
  ) {
    final grouped = <DateTime, List<TransactionEntity>>{};

    for (final tx in transactions) {
      final date = tx.date.value;
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((date) {
      return TransactionSection(
        title: _formatSectionDate(date),
        transactions: grouped[date]!,
      );
    }).toList();
  }

  static String _formatSectionDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
