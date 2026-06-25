class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.isFallback,
    this.initialBalance = 0,
  });

  final int id;
  final String name;
  final bool isFallback;

  /// Баланс счёта на момент начала учёта (до первой транзакции).
  final double initialBalance;

  AccountEntity copyWith({
    int? id,
    String? name,
    bool? isFallback,
    double? initialBalance,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isFallback: isFallback ?? this.isFallback,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
