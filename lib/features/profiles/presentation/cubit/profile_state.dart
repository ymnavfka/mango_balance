import '../../domain/entities/profile.dart';

class ProfileState {
  ProfileState({required this.profiles, required this.activeProfile});

  factory ProfileState.initial() {
    return ProfileState(profiles: const [], activeProfile: null);
  }

  final List<ProfileEntity> profiles;
  final ProfileEntity? activeProfile;

  ProfileState copyWith({
    List<ProfileEntity>? profiles,
    ProfileEntity? activeProfile,
    bool clearActiveProfile = false,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: clearActiveProfile
          ? null
          : (activeProfile ?? this.activeProfile),
    );
  }
}
