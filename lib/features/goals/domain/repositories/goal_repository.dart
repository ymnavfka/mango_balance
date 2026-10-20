import '../goal.dart';

abstract class GoalRepository {
  /// Emits whenever persisted data used to build the goal snapshot changes.
  Stream<void> watchChanges();

  Future<GoalSnapshot> load(int profileId, {DateTime? now});

  Future<void> save(GoalPlan goal, {DateTime? now});

  Future<void> complete(int id, int profileId);

  Future<void> delete(int id, int profileId);

  /// Removes account references from goals while preserving their saved
  /// progress.
  Future<void> detachAccount(int accountId, int profileId);
}
