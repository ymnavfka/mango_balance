import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../../domain/entities/period_type.dart';
import '../cubit/statistics_cubit.dart';
import '../cubit/statistics_state.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/period_navigator.dart';
import '../widgets/period_selector.dart';
import '../widgets/time_series_bar_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoute.statistics),
      appBar: AppBar(title: const Text('Statistics')),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          final cubit = context.read<StatisticsCubit>();

          if (!snapshot.hasAnyTransactions) {
            return Column(
              children: [
                const SizedBox(height: 16),
                PeriodSelector(
                  selected: snapshot.periodType,
                  onSelected: cubit.selectPeriodType,
                ),
                const Expanded(
                  child: Center(child: Text('No transactions yet')),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                PeriodSelector(
                  selected: snapshot.periodType,
                  onSelected: cubit.selectPeriodType,
                ),
                const SizedBox(height: 8),
                if (snapshot.periodType != PeriodType.allTime)
                  PeriodNavigator(
                    label: snapshot.currentRange.label,
                    canGoBack: snapshot.canNavigateBack,
                    canGoForward: snapshot.canNavigateForward,
                    onBack: () => cubit.shiftAnchor(-1),
                    onForward: () => cubit.shiftAnchor(1),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Center(
                      child: Text(
                        'All time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                CategoryDonutChart(
                  title: 'Income by category',
                  total: snapshot.totalIncome,
                  breakdown: snapshot.incomeBreakdown,
                  accentColor: Colors.green,
                ),
                CategoryDonutChart(
                  title: 'Expenses by category',
                  total: snapshot.totalExpense,
                  breakdown: snapshot.expenseBreakdown,
                  accentColor: Colors.red,
                ),
                TimeSeriesBarChart(
                  buckets: snapshot.timeSeries,
                  periodType: snapshot.periodType,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
