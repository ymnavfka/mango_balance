class CategoryBreakdown {
  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.share,
    this.children = const [],
  });

  final int? categoryId;
  final String categoryName;
  final double amount;
  final double share;

  /// Категории, свёрнутые в эту запись (используется для группы «Другое»).
  /// Их [share] рассчитан относительно всего графика, а не только группы.
  final List<CategoryBreakdown> children;

  bool get hasChildren => children.isNotEmpty;
}
