import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/delete_profile.dart';
import '../../domain/usecases/rename_profile.dart';
import '../../domain/usecases/set_active_profile.dart';
import '../../domain/usecases/watch_active_profile.dart';
import '../../domain/usecases/watch_profiles.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.activeProfileHolder,
    required this.watchProfilesUseCase,
    required this.watchActiveProfileUseCase,
    required this.createProfileUseCase,
    required this.renameProfileUseCase,
    required this.setActiveProfileUseCase,
    required this.deleteProfileUseCase,
  }) : super(ProfileState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfileHolder;
  final WatchProfiles watchProfilesUseCase;
  final WatchActiveProfile watchActiveProfileUseCase;
  final CreateProfile createProfileUseCase;
  final RenameProfile renameProfileUseCase;
  final SetActiveProfile setActiveProfileUseCase;
  final DeleteProfile deleteProfileUseCase;

  late final StreamSubscription<List<ProfileEntity>> _profilesSubscription;
  late final StreamSubscription<ProfileEntity?> _activeSubscription;

  void _init() {
    _profilesSubscription = watchProfilesUseCase().listen((profiles) {
      emit(state.copyWith(profiles: profiles));
    });

    _activeSubscription = watchActiveProfileUseCase().listen((profile) {
      if (profile != null) {
        activeProfileHolder.update(profile.id);
      }
      emit(
        state.copyWith(
          activeProfile: profile,
          clearActiveProfile: profile == null,
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _profilesSubscription.cancel();
    await _activeSubscription.cancel();
    return super.close();
  }

  Future<void> createProfile({
    required String name,
    required bool includeStandardData,
  }) async {
    await createProfileUseCase(
      name: name,
      includeStandardData: includeStandardData,
    );
  }

  Future<void> renameProfile(int id, String name) async {
    await renameProfileUseCase(id, name);
  }

  Future<void> switchProfile(int id) async {
    await setActiveProfileUseCase(id);
  }

  Future<void> deleteProfile(int id) async {
    if (state.profiles.length <= 1) {
      throw Exception('Cannot delete the last profile');
    }
    if (state.activeProfile?.id == id) {
      throw Exception('Cannot delete the active profile');
    }
    await deleteProfileUseCase(id);
  }
}
