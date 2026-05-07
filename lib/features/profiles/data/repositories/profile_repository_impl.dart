import '../../../../core/database/app_database.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Stream<List<ProfileEntity>> watchProfiles() {
    return db.watchProfiles().map((list) => list.map(_mapToEntity).toList());
  }

  @override
  Stream<ProfileEntity?> watchActiveProfile() {
    return db.watchActiveProfile().map(
      (profile) => profile == null ? null : _mapToEntity(profile),
    );
  }

  @override
  Future<ProfileEntity?> activeProfile() async {
    final row = await db.activeProfile();
    return row == null ? null : _mapToEntity(row);
  }

  @override
  Future<int> createProfile({
    required String name,
    required bool includeStandardData,
  }) {
    return db.createProfile(
      name: name.trim(),
      includeStandardData: includeStandardData,
    );
  }

  @override
  Future<void> renameProfile(int id, String name) {
    return db.renameProfile(id, name.trim());
  }

  @override
  Future<void> setActiveProfile(int id) {
    return db.setActiveProfile(id);
  }

  @override
  Future<void> deleteProfile(int id) {
    return db.deleteProfile(id);
  }

  ProfileEntity _mapToEntity(Profile profile) {
    return ProfileEntity(
      id: profile.id,
      name: profile.name,
      isActive: profile.isActive,
    );
  }
}
