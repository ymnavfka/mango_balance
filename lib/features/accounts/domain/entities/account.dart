class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.isFallback,
  });

  final int id;
  final String name;
  final bool isFallback;

  AccountEntity copyWith({int? id, String? name, bool? isFallback}) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
