class CategoryBreakdown {
  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.share,
  });

  final int? categoryId;
  final String categoryName;
  final double amount;
  final double share;
}
