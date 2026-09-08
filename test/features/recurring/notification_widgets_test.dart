import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/services/notification_service.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_cubit.dart';
import 'package:mango_balance/features/recurring/presentation/cubit/recurring_state.dart';
import 'package:mango_balance/features/recurring/presentation/widgets/notification_access_hint.dart';
import 'package:mango_balance/features/recurring/presentation/widgets/recurring_payment_card.dart';

import 'notification_flow_test.dart' as fixtures;

class SettingsNotifications extends NotificationService {
  int opens = 0;
  @override
  Future<bool> openSettings() async {
    opens++;
    return true;
  }
}

class SettingsCubit extends Fake implements RecurringCubit {
  @override
  final SettingsNotifications notificationService = SettingsNotifications();
  @override
  RecurringState get state => RecurringState.initial();
  @override
  Stream<RecurringState> get stream => const Stream.empty();
}

void main() {
  testWidgets(
    'card distinguishes enabled, unselected, blocked and paused reminders',
    (tester) async {
      var blockedTaps = 0;
      var cardTaps = 0;
      Future<void> showCard(
        NotificationAccess access, {
        bool notify = true,
        bool active = true,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecurringPaymentCard(
                payment: fixtures.payment(notify: notify, active: active),
                notificationAccess: access,
                onNotificationBlocked: () => blockedTaps++,
                onTap: () => cardTaps++,
                onToggleActive: (_) {},
              ),
            ),
          ),
        );
      }

      await showCard(NotificationAccess.enabled);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      await showCard(NotificationAccess.disabled, notify: false);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsNothing);
      await showCard(NotificationAccess.disabled);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      expect(blockedTaps, 1);
      expect(cardTaps, 0);
      await showCard(NotificationAccess.disabled, active: false);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings require a tap; dismissing help opens nothing', (
    tester,
  ) async {
    final cubit = SettingsCubit();
    await tester.pumpWidget(
      BlocProvider<RecurringCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showNotificationHelp(context),
                child: const Text('Help'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(cubit.notificationService.opens, 0);
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    expect(cubit.notificationService.opens, 0);
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть настройки'));
    await tester.pumpAndSettle();
    expect(cubit.notificationService.opens, 1);
  });

  testWidgets('compact hint offers settings only for blocked access', (
    tester,
  ) async {
    final cubit = SettingsCubit();
    Future<void> showHint(NotificationAccess access) => tester.pumpWidget(
      BlocProvider<RecurringCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: NotificationAccessHint(access: access),
            ),
          ),
        ),
      ),
    );
    await showHint(NotificationAccess.disabled);
    expect(find.text('Напоминания заблокированы'), findsOneWidget);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(cubit.notificationService.opens, 1);
    expect(tester.takeException(), isNull);
    await showHint(NotificationAccess.enabled);
    expect(find.text('Настройки'), findsNothing);
    await showHint(NotificationAccess.unsupported);
    expect(find.text('Настройки'), findsNothing);
    expect(find.text('Напоминания здесь недоступны'), findsOneWidget);
  });
}
