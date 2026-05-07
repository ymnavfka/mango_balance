class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final int id;
  final String name;
  final bool isActive;

  ProfileEntity copyWith({int? id, String? name, bool? isActive}) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
