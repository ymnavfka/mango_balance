import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../../../features/accounts/data/repositories/account_repository_impl.dart';
import '../../../features/accounts/domain/repositories/account_repository.dart';
import '../../../features/accounts/domain/usecases/add_account.dart';
import '../../../features/accounts/domain/usecases/delete_account.dart';
import '../../../features/accounts/domain/usecases/update_account.dart';
import '../../../features/accounts/domain/usecases/watch_accounts.dart';
import '../../../features/accounts/presentation/cubit/account_cubit.dart';
import '../../../features/categories/data/repositories/category_repository_impl.dart';
import '../../../features/categories/domain/repositories/category_repository.dart';
import '../../../features/categories/domain/usecases/add_category.dart';
import '../../../features/categories/domain/usecases/delete_category.dart';
import '../../../features/categories/domain/usecases/update_category.dart';
import '../../../features/categories/domain/usecases/watch_categories.dart';
import '../../../features/categories/presentation/cubit/category_cubit.dart';
import '../../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../../features/transactions/domain/usecases/add_transaction.dart';
import '../../../features/transactions/domain/usecases/delete_transaction.dart';
import '../../../features/transactions/domain/usecases/update_transaction.dart';
import '../../../features/transactions/domain/usecases/watch_transactions.dart';
import '../../../features/transactions/presentation/cubit/transaction_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Repositories
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt()),
  );

  // Transaction UseCases
  getIt.registerLazySingleton(() => AddTransaction(getIt()));
  getIt.registerLazySingleton(() => UpdateTransaction(getIt()));
  getIt.registerLazySingleton(() => DeleteTransaction(getIt()));
  getIt.registerLazySingleton(() => WatchTransactions(getIt()));

  // Account UseCases
  getIt.registerLazySingleton(() => AddAccount(getIt()));
  getIt.registerLazySingleton(() => UpdateAccount(getIt()));
  getIt.registerLazySingleton(() => DeleteAccount(getIt()));
  getIt.registerLazySingleton(() => WatchAccounts(getIt()));

  // Category UseCases
  getIt.registerLazySingleton(() => AddCategory(getIt()));
  getIt.registerLazySingleton(() => UpdateCategory(getIt()));
  getIt.registerLazySingleton(() => DeleteCategory(getIt()));
  getIt.registerLazySingleton(() => WatchCategories(getIt()));

  // Cubits
  getIt.registerFactory(
    () => TransactionCubit(
      addTransactionUseCase: getIt(),
      updateTransactionUseCase: getIt(),
      deleteTransactionUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => AccountCubit(
      watchAccountsUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
      addAccountUseCase: getIt(),
      updateAccountUseCase: getIt(),
      deleteAccountUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => CategoryCubit(
      watchCategoriesUseCase: getIt(),
      addCategoryUseCase: getIt(),
      updateCategoryUseCase: getIt(),
      deleteCategoryUseCase: getIt(),
    ),
  );
}
