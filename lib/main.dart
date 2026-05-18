import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injector.dart';
import 'features/accounts/presentation/cubit/account_cubit.dart';
import 'features/accounts/presentation/pages/accounts_page.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/categories/presentation/pages/categories_page.dart';
import 'features/budgets/presentation/cubit/budget_cubit.dart';
import 'features/budgets/presentation/pages/budgets_page.dart';
import 'features/profiles/presentation/cubit/profile_cubit.dart';
import 'features/profiles/presentation/pages/profiles_page.dart';
import 'features/statistics/presentation/cubit/statistics_cubit.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/transactions/presentation/cubit/transaction_cubit.dart';
import 'features/transactions/presentation/pages/transactions_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(create: (_) => getIt<ProfileCubit>()),
        BlocProvider<TransactionCubit>(
          create: (_) => getIt<TransactionCubit>(),
        ),
        BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
        BlocProvider<AccountCubit>(create: (_) => getIt<AccountCubit>()),
        BlocProvider<StatisticsCubit>(create: (_) => getIt<StatisticsCubit>()),
        BlocProvider<BudgetCubit>(create: (_) => getIt<BudgetCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        routes: {
          '/': (_) => const TransactionsPage(),
          '/statistics': (_) => const StatisticsPage(),
          '/budgets': (_) => const BudgetsPage(),
          '/categories': (_) => const CategoriesPage(),
          '/accounts': (_) => const AccountsPage(),
          '/profiles': (_) => const ProfilesPage(),
        },
      ),
    );
  }
}
