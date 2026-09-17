import 'adaptive_header_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profiles/presentation/cubit/profile_cubit.dart';
import '../../profiles/presentation/cubit/profile_state.dart';
import '../theme/app_colors.dart';

enum AppRoute {
  transactions,
  statistics,
  budgets,
  recurring,
  categories,
  accounts,
  profiles,
}

extension AppRouteX on AppRoute {
  String get routeName {
    switch (this) {
      case AppRoute.transactions:
        return '/';
      case AppRoute.statistics:
        return '/statistics';
      case AppRoute.budgets:
        return '/budgets';
      case AppRoute.recurring:
        return '/recurring';
      case AppRoute.categories:
        return '/categories';
      case AppRoute.accounts:
        return '/accounts';
      case AppRoute.profiles:
        return '/profiles';
    }
  }

  String get title {
    switch (this) {
      case AppRoute.transactions:
        return 'Транзакции';
      case AppRoute.statistics:
        return 'Статистика';
      case AppRoute.budgets:
        return 'Бюджеты';
      case AppRoute.recurring:
        return 'Регулярные платежи';
      case AppRoute.categories:
        return 'Категории';
      case AppRoute.accounts:
        return 'Счета';
      case AppRoute.profiles:
        return 'Профили';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRoute.transactions:
        return Icons.receipt_long_rounded;
      case AppRoute.statistics:
        return Icons.insights_rounded;
      case AppRoute.budgets:
        return Icons.savings_rounded;
      case AppRoute.recurring:
        return Icons.event_repeat_rounded;
      case AppRoute.categories:
        return Icons.category_rounded;
      case AppRoute.accounts:
        return Icons.account_balance_wallet_rounded;
      case AppRoute.profiles:
        return Icons.people_alt_rounded;
    }
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final AppRoute currentRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: 300,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: AdaptiveHeaderScrollView(
          header: [
            // Брендовая шапка.
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brand, Color(0xFF7C6CF5)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Манго Баланс',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      final name = state.activeProfile?.name ?? '—';
                      return Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          slivers: [
            // Навигация.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.list(
                children: AppRoute.values.map((route) {
                  final selected = route == currentRoute;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: selected
                          ? AppColors.brandContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () {
                          Navigator.of(context).pop();
                          if (route == currentRoute) return;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(route.routeName);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                route.icon,
                                size: 22,
                                color: selected
                                    ? AppColors.brand
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  route.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: selected
                                        ? AppColors.brandDark
                                        : AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Манго Баланс · v1.0',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
