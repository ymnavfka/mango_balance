import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../domain/entities/period_type.dart';
import '../cubit/statistics_cubit.dart';
import '../cubit/statistics_state.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/net_worth_line_chart.dart';
import '../widgets/period_navigator.dart';
import '../widgets/period_selector.dart';
import '../widgets/time_series_bar_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.statistics),
      appBar: AppBar(title: const Text('Статистика')),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          final cubit = context.read<StatisticsCubit>();

          if (!snapshot.hasAnyTransactions) {
            return Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                PeriodSelector(
                  selected: snapshot.periodType,
                  onSelected: cubit.selectPeriodType,
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'Пока нет данных',
                    message:
                        'Добавьте операции, чтобы увидеть статистику доходов '
                        'и расходов.',
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 24),
            child: Column(
              children: [
                PeriodSelector(
                  selected: snapshot.periodType,
                  onSelected: cubit.selectPeriodType,
                ),
                const SizedBox(height: AppSpacing.md),
                if (snapshot.periodType != PeriodType.allTime)
                  PeriodNavigator(
                    label: snapshot.currentRange.label,
                    canGoBack: snapshot.canNavigateBack,
                    canGoForward: snapshot.canNavigateForward,
                    onBack: () => cubit.shiftAnchor(-1),
                    onForward: () => cubit.shiftAnchor(1),
                  )
                else
                  const _AllTimeBadge(),
                const SizedBox(height: AppSpacing.xs),
                CategoryDonutChart(
                  title: 'Доходы по категориям',
                  total: snapshot.totalIncome,
                  breakdown: snapshot.incomeBreakdown,
                  accentColor: AppColors.income,
                  icon: Icons.south_west_rounded,
                ),
                CategoryDonutChart(
                  title: 'Расходы по категориям',
                  total: snapshot.totalExpense,
                  breakdown: snapshot.expenseBreakdown,
                  accentColor: AppColors.expense,
                  icon: Icons.north_east_rounded,
                ),
                TimeSeriesBarChart(
                  buckets: snapshot.timeSeries,
                  periodType: snapshot.periodType,
                ),
                NetWorthLineChart(points: snapshot.netWorthSeries),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AllTimeBadge extends StatelessWidget {
  const _AllTimeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Center(
        child: Text(
          'За всё время',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
