import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../../features/transactions/domain/usecases/add_transaction.dart';
import '../../../features/transactions/domain/usecases/update_transaction.dart';
import '../../../features/transactions/domain/usecases/delete_transaction.dart';
import '../../../features/transactions/domain/usecases/watch_transactions.dart';
import '../../../features/transactions/presentation/cubit/transaction_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Repository
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(getIt()),
  );

  // UseCases
  getIt.registerLazySingleton(() => AddTransaction(getIt()));
  getIt.registerLazySingleton(() => UpdateTransaction(getIt()));
  getIt.registerLazySingleton(() => DeleteTransaction(getIt()));
  getIt.registerLazySingleton(() => WatchTransactions(getIt()));

  // Cubit
  getIt.registerFactory(
    () => TransactionCubit(
      addTransactionUseCase: getIt(),
      updateTransactionUseCase: getIt(),
      deleteTransactionUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
    ),
  );
}
