import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'features/accounts/presentation/cubit/account_cubit.dart';
import 'features/accounts/presentation/pages/accounts_page.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/categories/presentation/pages/categories_page.dart';
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
        BlocProvider<TransactionCubit>(
          create: (_) => getIt<TransactionCubit>(),
        ),
        BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
        BlocProvider<AccountCubit>(create: (_) => getIt<AccountCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const TransactionsPage(),
          '/categories': (_) => const CategoriesPage(),
          '/accounts': (_) => const AccountsPage(),
        },
      ),
    );
  }
}
