import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/transactions/presentation/cubit/transaction_cubit.dart';
import 'features/transactions/presentation/pages/transactions_page.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  final database = AppDatabase();
  final repository = TransactionRepositoryImpl(database);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final TransactionRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => TransactionCubit(repository),
        child: const TransactionsPage(),
      ),
    );
  }
}
