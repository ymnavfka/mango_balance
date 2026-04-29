import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/transactions/presentation/cubit/transaction_cubit.dart';
import 'features/transactions/presentation/pages/transactions_page.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/usecases/add_transaction.dart';
import 'features/transactions/domain/usecases/update_transaction.dart';
import 'features/transactions/domain/usecases/delete_transaction.dart';
import 'features/transactions/domain/usecases/watch_transactions.dart';

void main() {
  final database = AppDatabase();
  final repository = TransactionRepositoryImpl(database);

  final addTransactionUseCase = AddTransaction(repository);
  final updateTransactionUseCase = UpdateTransaction(repository);
  final deleteTransactionUseCase = DeleteTransaction(repository);
  final watchTransactionsUseCase = WatchTransactions(repository);

  runApp(
    MyApp(
      addTransactionUseCase: addTransactionUseCase,
      updateTransactionUseCase: updateTransactionUseCase,
      deleteTransactionUseCase: deleteTransactionUseCase,
      watchTransactionsUseCase: watchTransactionsUseCase,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.watchTransactionsUseCase,
  });

  final AddTransaction addTransactionUseCase;
  final UpdateTransaction updateTransactionUseCase;
  final DeleteTransaction deleteTransactionUseCase;
  final WatchTransactions watchTransactionsUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => TransactionCubit(
          addTransactionUseCase: addTransactionUseCase,
          updateTransactionUseCase: updateTransactionUseCase,
          deleteTransactionUseCase: deleteTransactionUseCase,
          watchTransactionsUseCase: watchTransactionsUseCase,
        ),
        child: const TransactionsPage(),
      ),
    );
  }
}
