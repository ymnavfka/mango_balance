import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../services/active_profile_holder.dart';
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
import '../../../features/profiles/data/repositories/profile_repository_impl.dart';
import '../../../features/profiles/domain/repositories/profile_repository.dart';
import '../../../features/profiles/domain/usecases/create_profile.dart';
import '../../../features/profiles/domain/usecases/delete_profile.dart';
import '../../../features/profiles/domain/usecases/rename_profile.dart';
import '../../../features/profiles/domain/usecases/set_active_profile.dart';
import '../../../features/profiles/domain/usecases/watch_active_profile.dart';
import '../../../features/profiles/domain/usecases/watch_profiles.dart';
import '../../../features/profiles/presentation/cubit/profile_cubit.dart';
import '../../../features/budgets/data/repositories/budget_repository_impl.dart';
import '../../../features/budgets/domain/repositories/budget_repository.dart';
import '../../../features/budgets/domain/usecases/add_budget.dart';
import '../../../features/budgets/domain/usecases/build_budgets_progress.dart';
import '../../../features/budgets/domain/usecases/delete_budget.dart';
import '../../../features/budgets/domain/usecases/update_budget.dart';
import '../../../features/budgets/domain/usecases/watch_budgets.dart';
import '../../../features/budgets/presentation/cubit/budget_cubit.dart';
import '../../../features/recurring/data/repositories/recurring_repository_impl.dart';
import '../../../features/recurring/domain/repositories/recurring_repository.dart';
import '../../../features/recurring/domain/usecases/add_recurring_payment.dart';
import '../../../features/recurring/domain/usecases/delete_recurring_payment.dart';
import '../../../features/recurring/domain/usecases/run_due_recurring_payments.dart';
import '../../../features/recurring/domain/usecases/set_recurring_active.dart';
import '../../../features/recurring/domain/usecases/update_recurring_payment.dart';
import '../../../features/recurring/domain/usecases/watch_recurring_payments.dart';
import '../../../features/recurring/presentation/cubit/recurring_cubit.dart';
import '../../../features/statistics/domain/usecases/build_category_breakdown.dart';
import '../../../features/statistics/domain/usecases/build_net_worth_series.dart';
import '../../../features/statistics/domain/usecases/build_statistics_snapshot.dart';
import '../../../features/statistics/domain/usecases/build_time_series.dart';
import '../../../features/statistics/domain/usecases/compute_period_range.dart';
import '../../../features/statistics/presentation/cubit/statistics_cubit.dart';
import '../../../features/export/data/file_writers/xlsx_file_saver.dart';
import '../../../features/export/data/repositories/export_repository_impl.dart';
import '../../../features/export/domain/repositories/export_repository.dart';
import '../../../features/export/domain/usecases/build_xlsx_export.dart';
import '../../../features/export/presentation/cubit/export_cubit.dart';
import '../../../features/import/data/parsers/xlsx_import_parser.dart';
import '../../../features/import/data/repositories/import_repository_impl.dart';
import '../../../features/import/domain/repositories/import_repository.dart';
import '../../../features/import/domain/usecases/import_to_profile.dart';
import '../../../features/import/domain/usecases/parse_xlsx_file.dart';
import '../../../features/import/presentation/cubit/import_cubit.dart';
import '../../../features/transactions/data/datasources/date_range_filter_storage.dart';
import '../../../features/transactions/data/datasources/transaction_type_filter_storage.dart';
import '../../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../../features/transactions/domain/usecases/add_transaction.dart';
import '../../../features/transactions/domain/usecases/calculate_account_balances.dart';
import '../../../features/transactions/domain/usecases/delete_transaction.dart';
import '../../../features/transactions/domain/usecases/filter_transactions_by_account.dart';
import '../../../features/transactions/domain/usecases/filter_transactions_by_date_range.dart';
import '../../../features/transactions/domain/usecases/filter_transactions_by_type.dart';
import '../../../features/transactions/domain/usecases/update_transaction.dart';
import '../../../features/transactions/domain/usecases/watch_transactions.dart';
import '../../../features/transactions/presentation/cubit/transaction_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton(() => TransactionTypeFilterStorage(getIt()));
  getIt.registerLazySingleton(() => DateRangeFilterStorage(getIt()));

  // Active profile holder seeded from DB
  final initialActive = await database.activeProfile();
  getIt.registerSingleton<ActiveProfileHolder>(
    ActiveProfileHolder(initialId: initialActive?.id ?? 1),
  );

  // Repositories
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<ImportRepository>(
    () => ImportRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<ExportRepository>(
    () => ExportRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<RecurringRepository>(
    () => RecurringRepositoryImpl(getIt(), getIt()),
  );

  // Transaction UseCases
  getIt.registerLazySingleton(() => AddTransaction(getIt()));
  getIt.registerLazySingleton(() => UpdateTransaction(getIt()));
  getIt.registerLazySingleton(() => DeleteTransaction(getIt()));
  getIt.registerLazySingleton(() => WatchTransactions(getIt()));
  getIt.registerLazySingleton(() => CalculateAccountBalances());
  getIt.registerLazySingleton(() => FilterTransactionsByAccount());
  getIt.registerLazySingleton(() => FilterTransactionsByType());
  getIt.registerLazySingleton(() => FilterTransactionsByDateRange());

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

  // Profile UseCases
  getIt.registerLazySingleton(() => WatchProfiles(getIt()));
  getIt.registerLazySingleton(() => WatchActiveProfile(getIt()));
  getIt.registerLazySingleton(() => CreateProfile(getIt()));
  getIt.registerLazySingleton(() => RenameProfile(getIt()));
  getIt.registerLazySingleton(() => SetActiveProfile(getIt()));
  getIt.registerLazySingleton(() => DeleteProfile(getIt()));

  // Import
  getIt.registerLazySingleton(() => XlsxImportParser());
  getIt.registerLazySingleton(() => ParseXlsxFile(getIt()));
  getIt.registerLazySingleton(() => ImportToProfile(getIt()));

  // Export
  getIt.registerLazySingleton(() => XlsxFileSaver());
  getIt.registerLazySingleton(() => BuildXlsxExport(getIt()));

  // Budgets
  getIt.registerLazySingleton(() => WatchBudgets(getIt()));
  getIt.registerLazySingleton(() => AddBudget(getIt()));
  getIt.registerLazySingleton(() => UpdateBudget(getIt()));
  getIt.registerLazySingleton(() => DeleteBudget(getIt()));
  getIt.registerLazySingleton(() => BuildBudgetsProgress());

  // Recurring payments
  getIt.registerLazySingleton(() => WatchRecurringPayments(getIt()));
  getIt.registerLazySingleton(() => AddRecurringPayment(getIt()));
  getIt.registerLazySingleton(() => UpdateRecurringPayment(getIt()));
  getIt.registerLazySingleton(() => DeleteRecurringPayment(getIt()));
  getIt.registerLazySingleton(() => SetRecurringActive(getIt()));
  getIt.registerLazySingleton(() => RunDueRecurringPayments(getIt(), getIt()));

  // Statistics
  getIt.registerLazySingleton(() => ComputePeriodRange());
  getIt.registerLazySingleton(() => BuildCategoryBreakdown());
  getIt.registerLazySingleton(() => BuildTimeSeries(getIt()));
  getIt.registerLazySingleton(() => BuildNetWorthSeries());
  getIt.registerLazySingleton(
    () => BuildStatisticsSnapshot(
      computePeriodRange: getIt(),
      buildCategoryBreakdown: getIt(),
      buildTimeSeries: getIt(),
      buildNetWorthSeries: getIt(),
    ),
  );

  // Cubits
  getIt.registerFactory(
    () => TransactionCubit(
      activeProfile: getIt(),
      addTransactionUseCase: getIt(),
      updateTransactionUseCase: getIt(),
      deleteTransactionUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
      watchAccountsUseCase: getIt(),
      calculateAccountBalancesUseCase: getIt(),
      filterTransactionsUseCase: getIt(),
      filterTransactionsByTypeUseCase: getIt(),
      filterTransactionsByDateRangeUseCase: getIt(),
      typeFilterStorage: getIt(),
      dateRangeFilterStorage: getIt(),
    ),
  );

  getIt.registerFactory(
    () => AccountCubit(
      activeProfile: getIt(),
      watchAccountsUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
      calculateAccountBalancesUseCase: getIt(),
      addAccountUseCase: getIt(),
      updateAccountUseCase: getIt(),
      deleteAccountUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => CategoryCubit(
      activeProfile: getIt(),
      watchCategoriesUseCase: getIt(),
      addCategoryUseCase: getIt(),
      updateCategoryUseCase: getIt(),
      deleteCategoryUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ProfileCubit(
      activeProfileHolder: getIt(),
      watchProfilesUseCase: getIt(),
      watchActiveProfileUseCase: getIt(),
      createProfileUseCase: getIt(),
      renameProfileUseCase: getIt(),
      setActiveProfileUseCase: getIt(),
      deleteProfileUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ImportCubit(
      parseXlsxFileUseCase: getIt(),
      importToProfileUseCase: getIt(),
      createProfileUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ExportCubit(buildXlsxExportUseCase: getIt(), fileSaver: getIt()),
  );

  getIt.registerFactory(
    () => StatisticsCubit(
      activeProfile: getIt(),
      watchTransactionsUseCase: getIt(),
      watchAccountsUseCase: getIt(),
      buildStatisticsSnapshotUseCase: getIt(),
      computePeriodRangeUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => BudgetCubit(
      activeProfile: getIt(),
      watchBudgetsUseCase: getIt(),
      watchTransactionsUseCase: getIt(),
      watchCategoriesUseCase: getIt(),
      addBudgetUseCase: getIt(),
      updateBudgetUseCase: getIt(),
      deleteBudgetUseCase: getIt(),
      buildBudgetsProgressUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => RecurringCubit(
      activeProfile: getIt(),
      watchRecurringPaymentsUseCase: getIt(),
      addRecurringPaymentUseCase: getIt(),
      updateRecurringPaymentUseCase: getIt(),
      deleteRecurringPaymentUseCase: getIt(),
      setRecurringActiveUseCase: getIt(),
      runDueRecurringPaymentsUseCase: getIt(),
    ),
  );
}
