import '../../domain/entities/statistics_snapshot.dart';

class StatisticsState {
  StatisticsState({required this.snapshot});

  factory StatisticsState.initial() {
    return StatisticsState(snapshot: StatisticsSnapshot.empty());
  }

  final StatisticsSnapshot snapshot;

  StatisticsState copyWith({StatisticsSnapshot? snapshot}) {
    return StatisticsState(snapshot: snapshot ?? this.snapshot);
  }
}
