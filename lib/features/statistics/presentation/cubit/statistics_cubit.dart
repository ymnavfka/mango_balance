import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/active_profile_holder.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/usecases/watch_transactions.dart';
import '../../domain/entities/period_type.dart';
import '../../domain/usecases/build_statistics_snapshot.dart';
import '../../domain/usecases/compute_period_range.dart';
import 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({
    required this.activeProfile,
    required this.watchTransactionsUseCase,
    required this.buildStatisticsSnapshotUseCase,
    required this.computePeriodRangeUseCase,
  }) : super(StatisticsState.initial()) {
    _init();
  }

  final ActiveProfileHolder activeProfile;
  final WatchTransactions watchTransactionsUseCase;
  final BuildStatisticsSnapshot buildStatisticsSnapshotUseCase;
  final ComputePeriodRange computePeriodRangeUseCase;

  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  late final StreamSubscription<int> _profileSubscription;

  List<TransactionEntity> _transactions = [];
  PeriodType _periodType = PeriodType.week;
  DateTime _anchorDate = DateTime.now();

  void _init() {
    _resubscribe(activeProfile.id);
    _profileSubscription = activeProfile.stream.listen(_resubscribe);
  }

  void _resubscribe(int profileId) {
    _transactionsSubscription?.cancel();
    _transactions = [];
    _periodType = PeriodType.week;
    _anchorDate = DateTime.now();
    emit(StatisticsState.initial());

    _transactionsSubscription = watchTransactionsUseCase(profileId).listen((
      list,
    ) {
      _transactions = list;
      _recompute();
    });
  }

  @override
  Future<void> close() async {
    await _transactionsSubscription?.cancel();
    await _profileSubscription.cancel();
    return super.close();
  }

  void selectPeriodType(PeriodType type) {
    if (_periodType == type) return;
    _periodType = type;
    _anchorDate = DateTime.now();
    _recompute();
  }

  void shiftAnchor(int direction) {
    if (_periodType == PeriodType.allTime) return;
    final next = computePeriodRangeUseCase.shiftAnchor(
      type: _periodType,
      anchor: _anchorDate,
      direction: direction,
    );
    if (direction > 0 && next.isAfter(DateTime.now())) {
      return;
    }
    _anchorDate = next;
    _recompute();
  }

  void _recompute() {
    final snapshot = buildStatisticsSnapshotUseCase(
      transactions: _transactions,
      periodType: _periodType,
      anchorDate: _anchorDate,
      now: DateTime.now(),
    );
    emit(state.copyWith(snapshot: snapshot));
  }
}
