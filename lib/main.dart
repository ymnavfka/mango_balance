import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injector.dart';
import 'features/shared/theme/app_theme.dart';
import 'features/accounts/presentation/cubit/account_cubit.dart';
import 'features/accounts/presentation/pages/accounts_page.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/categories/presentation/pages/categories_page.dart';
import 'features/budgets/presentation/cubit/budget_cubit.dart';
import 'features/budgets/presentation/pages/budgets_page.dart';
import 'features/recurring/presentation/cubit/recurring_cubit.dart';
import 'features/recurring/presentation/pages/recurring_payments_page.dart';
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

/// Штатный размер окна (см. gtk_window_set_default_size в linux/runner).
/// Используется как размер раскладки на вырожденном первом кадре.
const double _fallbackWindowWidth = 1280;
const double _fallbackWindowHeight = 720;

/// Разрешает прокрутку перетаскиванием мышью (и стилусом) — на десктопе Flutter
/// по умолчанию её нет, поэтому горизонтальные графики и списки нельзя было
/// «тянуть» мышью, как на телефоне. Колесо мыши и трекпад продолжают работать.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
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
        // lazy: false — планировщик регулярных платежей должен запускаться при
        // старте приложения и при смене профиля, даже если экран не открыт.
        BlocProvider<RecurringCubit>(
          create: (_) => getIt<RecurringCubit>(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mango Balance',
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.light(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              // На первом кадре под Linux/GTK (и при перерисовке в тайлинговых
              // WM) окну кратко выдаётся вырожденный размер ~1×1 до того, как
              // менеджер окон сообщит реальную геометрию. На таком кадре
              // раскладываем интерфейс в штатном размере окна, иначе внутренние
              // Row/Column переполняются. Реальные размеры окна не трогаем.
              final degenerate =
                  !constraints.maxWidth.isFinite ||
                  !constraints.maxHeight.isFinite ||
                  constraints.maxWidth < 50 ||
                  constraints.maxHeight < 50;
              final width = degenerate
                  ? _fallbackWindowWidth
                  : constraints.maxWidth;
              final height = degenerate
                  ? _fallbackWindowHeight
                  : constraints.maxHeight;
              return OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: content,
              );
            },
          );
        },
        initialRoute: '/',
        routes: {
          '/': (_) => const TransactionsPage(),
          '/statistics': (_) => const StatisticsPage(),
          '/budgets': (_) => const BudgetsPage(),
          '/recurring': (_) => const RecurringPaymentsPage(),
          '/categories': (_) => const CategoriesPage(),
          '/accounts': (_) => const AccountsPage(),
          '/profiles': (_) => const ProfilesPage(),
        },
      ),
    );
  }
}
