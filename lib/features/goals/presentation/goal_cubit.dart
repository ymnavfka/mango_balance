import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/active_profile_holder.dart';
import '../../../core/services/app_error_notifier.dart';
import '../domain/goal.dart';
import '../domain/usecases/complete_goal.dart';
import '../domain/usecases/delete_goal.dart';
import '../domain/usecases/load_goal_snapshot.dart';
import '../domain/usecases/save_goal.dart';
import '../domain/usecases/watch_goal_changes.dart';

class GoalCubit extends Cubit<GoalSnapshot> with WidgetsBindingObserver {
  GoalCubit({
    required this.profile,
    required this.watchGoalChangesUseCase,
    required this.loadGoalSnapshotUseCase,
    required this.saveGoalUseCase,
    required this.completeGoalUseCase,
    required this.deleteGoalUseCase,
  }) : super(const GoalSnapshot()) {
    WidgetsBinding.instance.addObserver(this);
    _updates = watchGoalChangesUseCase().listen((_) => refresh());
    _profiles = profile.stream.listen((_) {
      emit(const GoalSnapshot());
      refresh();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    refresh();
  }
  final ActiveProfileHolder profile;
  final WatchGoalChanges watchGoalChangesUseCase;
  final LoadGoalSnapshot loadGoalSnapshotUseCase;
  final SaveGoal saveGoalUseCase;
  final CompleteGoal completeGoalUseCase;
  final DeleteGoal deleteGoalUseCase;
  late final StreamSubscription<void> _updates;
  late final StreamSubscription<int> _profiles;
  late final Timer _timer;
  bool _loading = false, _again = false;
  Future<void> refresh() async {
    if (isClosed) return;
    if (_loading) {
      _again = true;
      return;
    }
    _loading = true;
    try {
      do {
        _again = false;
        final id = profile.id;
        final snapshot = await loadGoalSnapshotUseCase(id);
        if (!isClosed && id == profile.id) emit(snapshot);
      } while (_again && !isClosed);
    } catch (error) {
      showAppError(error);
    } finally {
      _loading = false;
    }
  }

  Future<void> save(GoalPlan goal) async {
    await saveGoalUseCase(goal);
    await refresh();
  }

  Future<void> complete(int id) async {
    await completeGoalUseCase(id, profile.id);
    await refresh();
  }

  Future<void> delete(int id) async {
    await deleteGoalUseCase(id, profile.id);
    await refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    await _updates.cancel();
    await _profiles.cancel();
    return super.close();
  }
}
