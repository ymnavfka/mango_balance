// Store artwork harness. Renders production widgets from the delivered XLSX.
// Run: flutter test tool/capture_store_test.dart
import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/core/services/notification_service.dart';
import 'package:mango_balance/features/import/data/parsers/xlsx_import_parser.dart';
import 'package:mango_balance/features/accounts/domain/entities/account.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_cubit.dart';
import 'package:mango_balance/features/accounts/presentation/cubit/account_state.dart';
import 'package:mango_balance/features/accounts/presentation/pages/accounts_page.dart';
import 'package:mango_balance/features/categories/domain/entities/category.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_cubit.dart';
import 'package:mango_balance/features/categories/presentation/cubit/category_state.dart';
import 'package:mango_balance/features/transactions/domain/entities/transaction.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/amount.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/transaction_date.dart';
import 'package:mango_balance/features/transactions/domain/usecases/calculate_account_balances.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:mango_balance/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:mango_balance/features/transactions/presentation/pages/transactions_page.dart';
import 'package:mango_balance/features/budgets/domain/entities/budget.dart';
import 'package:mango_balance/features/budgets/domain/entities/budget_period.dart';
import 'package:mango_balance/features/budgets/domain/usecases/build_budgets_progress.dart';
import 'package:mango_balance/features/budgets/presentation/cubit/budget_cubit.dart';
import 'package:mango_balance/features/budgets/presentation/cubit/budget_state.dart';
import 'package:mango_balance/features/budgets/presentation/pages/budgets_page.dart';
import 'package:mango_balance/features/statistics/domain/entities/period_type.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_statistics_snapshot.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_category_breakdown.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_net_worth_series.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_time_series.dart';
import 'package:mango_balance/features/statistics/domain/usecases/compute_period_range.dart';
import 'package:mango_balance/features/statistics/presentation/cubit/statistics_cubit.dart';
import 'package:mango_balance/features/statistics/presentation/cubit/statistics_state.dart';
import 'package:mango_balance/features/statistics/presentation/pages/statistics_page.dart';
import 'package:mango_balance/features/recurring/domain/entities/recurring_payment.dart';
import 'package:mango_balance/features/recurring/domain/entities/recurring_interval.dart';
import 'package:mango_balance/features/recurring/domain/entities/notify_lead.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_cubit.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_state.dart';
import 'package:mango_balance/features/recurring/presentation/pages/recurring_payments_page.dart';
import 'package:mango_balance/features/profiles/domain/entities/profile.dart';
import 'package:mango_balance/features/profiles/presentation/cubit/profile_cubit.dart';
import 'package:mango_balance/features/profiles/presentation/cubit/profile_state.dart';
import 'package:mango_balance/features/profiles/presentation/pages/profiles_page.dart';
import 'package:mango_balance/features/shared/theme/app_theme.dart';

class CaptureAccounts extends Cubit<AccountState> implements AccountCubit {
  CaptureAccounts(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureTransactions extends Cubit<TransactionState> implements TransactionCubit {
  CaptureTransactions(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureCategories extends Cubit<CategoryState> implements CategoryCubit {
  CaptureCategories(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureBudgets extends Cubit<BudgetState> implements BudgetCubit {
  CaptureBudgets(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureStatistics extends Cubit<StatisticsState> implements StatisticsCubit {
  CaptureStatistics(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureRecurring extends Cubit<RecurringState> implements RecurringCubit {
  CaptureRecurring(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class CaptureProfiles extends Cubit<ProfileState> implements ProfileCubit {
  CaptureProfiles(super.state);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('validate demo import and render store screens', (tester) async {
    const root='outputs/rustore-2026-10';
    // Use the original demo records in memory: the artwork workbook uses
    // namespaced styles that excel 4.x does not read.
    final records=jsonDecode(File('$root/source/demo-data.json').readAsStringSync())['sheets'] as Map<String,dynamic>;
    final workbook=xls.Excel.createExcel();
    for(final entry in records.entries){
      for(final row in entry.value as List){
        workbook[entry.key].appendRow((row as List).map<xls.CellValue?>((v)=>v==null?null:v is String && RegExp(r'^2026-\d\d-\d\dT').hasMatch(v)?xls.DoubleCellValue(DateTime.parse(v).difference(DateTime.utc(1899,12,30)).inMilliseconds/86400000):v is int?xls.IntCellValue(v):v is num?xls.DoubleCellValue(v.toDouble()):xls.TextCellValue(v.toString())).toList());
      }
    }
    final data=XlsxImportParser().parse(Uint8List.fromList(workbook.encode()!)).backup!;
    expect(data.profiles.length,3);expect(data.transactions.length,293);expect(data.budgets.length,5);expect(data.recurring.length,6);
    final font=FontLoader('Roboto');
    font.addFont(Future.value(ByteData.sublistView(File('/Users/tanya/Development/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf').readAsBytesSync())));
    font.addFont(Future.value(ByteData.sublistView(File('/Users/tanya/Development/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Medium.ttf').readAsBytesSync())));
    await font.load();
    final icons=FontLoader('MaterialIcons');
    icons.addFont(Future.value(ByteData.sublistView(File('/Users/tanya/Development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
    await icons.load();
    final accs=data.accounts.where((a)=>a.profileSourceId==1).map((a)=>AccountEntity(id:a.sourceId,name:a.name,isFallback:a.isFallback,initialBalance:a.initialBalance)).toList();
    final cats=data.categories.where((c)=>c.profileSourceId==1).map((c)=>CategoryEntity(id:c.sourceId,name:c.name,type:TransactionType.values.byName(c.type),isFallback:c.isFallback)).toList();
    final an={for(final a in data.accounts)a.sourceId:a.name};final cn={for(final c in data.categories)c.sourceId:c.name};
    int id=0;
    final txs=data.transactions.where((t)=>t.profileSourceId==1).map((t)=>TransactionEntity(id:++id,type:TransactionType.values.byName(t.type),amount:Amount(t.amount),date:TransactionDate(t.date),categoryId:t.categorySourceId??14,categoryName:cn[t.categorySourceId]??'Перевод',accountId:t.accountSourceId!,accountName:an[t.accountSourceId]!,toAccountId:t.toAccountSourceId,toAccountName:an[t.toAccountSourceId],comment:t.comment)).toList()..sort((a,b)=>b.date.value.compareTo(a.date.value));
    final balances=CalculateAccountBalances()(txs,initialBalances:{for(final a in accs)a.id:a.initialBalance});
    expect(balances,{1:48500.0,2:3150.0,3:145000.0,4:52000.0});
    final total=balances.values.fold(0.0,(a,b)=>a+b);
    // Every entry is imported; no illustrative UI numbers are injected.
    final sections=<TransactionSection>[];
    for(final day in txs.map((t)=>DateTime(t.date.value.year,t.date.value.month,t.date.value.day)).toSet()){
      final label=day==DateTime(2026,10,7)?'Сегодня':day==DateTime(2026,10,6)?'Вчера':'${day.day} ${day.month==10?'октября':'сентября'}';
      sections.add(TransactionSection(title:label,transactions:txs.where((t)=>DateUtils.isSameDay(t.date.value,day)).toList()));
    }
    final accountCubit=CaptureAccounts(AccountState(accounts:accs,balances:balances,totalBalance:total));
    final transactionCubit=CaptureTransactions(TransactionState.initial().copyWith(transactions:txs,allTransactions:txs,sections:sections,totalBalance:total,selectedBalance:total,accountBalances:balances));
    final categoryCubit=CaptureCategories(CategoryState(categories:cats));
    final now=DateTime(2026,10,7,12);
    final budgets=data.budgets.where((b)=>b.profileSourceId==1).map((b)=>BudgetEntity(id:b.sourceId,name:b.name,limitAmount:b.limitAmount,period:BudgetPeriod.values.byName(b.periodType),allCategories:b.allCategories,categoryIds:data.budgetCategories.where((l)=>l.budgetSourceId==b.sourceId).map((l)=>l.categorySourceId).toList())).toList();
    final budgetCubit=CaptureBudgets(BudgetState(progresses:BuildBudgetsProgress()(budgets:budgets,transactions:txs,categories:cats,now:now)));
    final snap=BuildStatisticsSnapshot(computePeriodRange:ComputePeriodRange(),buildCategoryBreakdown:BuildCategoryBreakdown(),buildTimeSeries:BuildTimeSeries(ComputePeriodRange()),buildNetWorthSeries:BuildNetWorthSeries())(transactions:txs,periodType:PeriodType.month,anchorDate:DateTime(2026,9,15),now:now,initialBalanceTotal:accs.fold(0.0,(s,a)=>s+a.initialBalance));
    final statsCubit=CaptureStatistics(StatisticsState(snapshot:snap));
    id=0;
    final recurringCubit=CaptureRecurring(RecurringState(notificationAccess:NotificationAccess.enabled,payments:data.recurring.where((r)=>r.profileSourceId==1).map((r)=>RecurringPaymentEntity(id:++id,name:r.name,type:TransactionType.values.byName(r.type),amount:r.amount,categoryId:r.categorySourceId!,categoryName:cn[r.categorySourceId]!,accountId:r.accountSourceId!,accountName:an[r.accountSourceId]!,intervalUnit:RecurringInterval.values.byName(r.intervalUnit),intervalCount:r.intervalCount,startDate:r.startDate,nextRunDate:r.nextRunDate,isActive:r.isActive,notifyValue:1,notifyUnit:NotifyLeadUnit.day)).toList()..sort((a,b)=>a.nextRunDate.compareTo(b.nextRunDate))));
    final profiles=data.profiles.map((p)=>ProfileEntity(id:p.sourceId,name:p.name,isActive:p.isActive)).toList();
    final profileCubit=CaptureProfiles(ProfileState(profiles:profiles,activeProfile:profiles.first));
    tester.view.physicalSize=const Size(430,760);tester.view.devicePixelRatio=1;
    final boundary=GlobalKey();
    Future<void> mount(Widget page) async {
      await tester.pumpWidget(MultiBlocProvider(providers:[BlocProvider<AccountCubit>.value(value:accountCubit),BlocProvider<TransactionCubit>.value(value:transactionCubit),BlocProvider<CategoryCubit>.value(value:categoryCubit),BlocProvider<BudgetCubit>.value(value:budgetCubit),BlocProvider<StatisticsCubit>.value(value:statsCubit),BlocProvider<RecurringCubit>.value(value:recurringCubit),BlocProvider<ProfileCubit>.value(value:profileCubit)],child:RepaintBoundary(key:boundary,child:MaterialApp(debugShowCheckedModeBanner:false,theme:AppTheme.light().copyWith(platform:TargetPlatform.android),locale:const Locale('ru'),supportedLocales:const[Locale('ru')],localizationsDelegates:GlobalMaterialLocalizations.delegates,home:page))));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    }
    Future<void> save(String name) async {
      await tester.runAsync(() async {final image=await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:3);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);File('$root/screenshots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();});
    }
    await mount(const TransactionsPage());await save('transactions');
    await mount(const AccountsPage());await save('accounts');
    await mount(const BudgetsPage());await save('budgets');
    await mount(const RecurringPaymentsPage());await save('recurring');
    await mount(const ProfilesPage());await save('profiles');
    await mount(const StatisticsPage());await save('statistics-top');
    await tester.scrollUntilVisible(find.text('Расходы по категориям'),450,scrollable:find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first,const Offset(0,35));
    await tester.pumpAndSettle();await save('statistics');
    await tester.pumpWidget(const SizedBox.shrink());
    for(final c in [accountCubit,transactionCubit,categoryCubit,budgetCubit,statsCubit,recurringCubit,profileCubit]){await c.close();}
    tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
  });
}
