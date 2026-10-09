import '../../../../core/enums/transaction_type.dart';

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.isFallback,
    this.isArchived = false,
  });

  final int id;
  final String name;
  final TransactionType type;
  final bool isFallback;
  final bool isArchived;

  CategoryEntity copyWith({
    int? id,
    String? name,
    TransactionType? type,
    bool? isFallback,
    bool? isArchived,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isFallback: isFallback ?? this.isFallback,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
