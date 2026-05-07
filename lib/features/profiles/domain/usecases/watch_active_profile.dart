import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class WatchActiveProfile {
  WatchActiveProfile(this.repository);

  final ProfileRepository repository;

  Stream<ProfileEntity?> call() => repository.watchActiveProfile();
}
