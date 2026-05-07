import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profiles/presentation/cubit/profile_cubit.dart';
import '../../profiles/presentation/cubit/profile_state.dart';

enum AppRoute { transactions, categories, accounts, profiles }

extension AppRouteX on AppRoute {
  String get routeName {
    switch (this) {
      case AppRoute.transactions:
        return '/';
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
        return 'Transactions';
      case AppRoute.categories:
        return 'Categories';
      case AppRoute.accounts:
        return 'Accounts';
      case AppRoute.profiles:
        return 'Profiles';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRoute.transactions:
        return Icons.list;
      case AppRoute.categories:
        return Icons.category;
      case AppRoute.accounts:
        return Icons.account_balance_wallet;
      case AppRoute.profiles:
        return Icons.person;
    }
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final AppRoute currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Mango Balance',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      final name = state.activeProfile?.name ?? '—';
                      return Text(
                        'Profile: $name',
                        style: const TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ...AppRoute.values.map((route) {
            return ListTile(
              leading: Icon(route.icon),
              title: Text(route.title),
              selected: route == currentRoute,
              onTap: () {
                Navigator.of(context).pop();
                if (route == currentRoute) {
                  return;
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed(route.routeName);
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
