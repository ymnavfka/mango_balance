import 'package:flutter/material.dart';

enum AppRoute { transactions, categories, accounts }

extension AppRouteX on AppRoute {
  String get routeName {
    switch (this) {
      case AppRoute.transactions:
        return '/';
      case AppRoute.categories:
        return '/categories';
      case AppRoute.accounts:
        return '/accounts';
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
              child: Text(
                'Mango Balance',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
