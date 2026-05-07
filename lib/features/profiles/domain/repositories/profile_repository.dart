import '../entities/profile.dart';

abstract class ProfileRepository {
  Stream<List<ProfileEntity>> watchProfiles();
  Stream<ProfileEntity?> watchActiveProfile();
  Future<ProfileEntity?> activeProfile();
  Future<int> createProfile({
    required String name,
    required bool includeStandardData,
  });
  Future<void> renameProfile(int id, String name);
  Future<void> setActiveProfile(int id);
  Future<void> deleteProfile(int id);
}
