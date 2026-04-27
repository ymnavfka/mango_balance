import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/transactions/presentation/cubit/transaction_cubit.dart';
import 'features/transactions/presentation/pages/transactions_page.dart';

void main() {
  final database = AppDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => TransactionCubit(database),
        child: const TransactionsPage(),
      ),
    );
  }
}