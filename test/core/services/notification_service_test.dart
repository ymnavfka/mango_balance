import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const settingsChannel = MethodChannel('mango_balance/notification_settings');
  final calls = <MethodCall>[];
  var enabled = false;
  var blockedChannel = false;
  var grantOnRequest = false;
  var fail = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    enabled = false;
    blockedChannel = false;
    grantOnRequest = false;
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (fail) throw PlatformException(code: 'unavailable');
          switch (call.method) {
            case 'initialize':
              return true;
            case 'areNotificationsEnabled':
              return enabled;
            case 'requestNotificationsPermission':
              enabled = grantOnRequest;
              return grantOnRequest;
            case 'getNotificationChannels':
              return blockedChannel
                  ? [
                      {
                        'id': 'recurring_reminders',
                        'name': 'Напоминания о платежах',
                        'importance': 0,
                        'bypassDnd': false,
                        'ledColor': 0,
                        'playSound': false,
                        'enableVibration': false,
                        'showBadge': false,
                        'enableLights': false,
                      },
                    ]
                  : [];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, null);
  });

  test(
    'settings open only when explicitly requested and target reminders',
    () async {
      MethodCall? settingsCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(settingsChannel, (call) async {
            settingsCall = call;
            return true;
          });
      final service = NotificationService();
      await service.access();
      expect(settingsCall, isNull);
      expect(await service.openSettings(), true);
      expect(settingsCall?.method, 'openNotificationSettings');
      expect(settingsCall?.arguments, {'channelId': 'recurring_reminders'});
      expect(calls.where((call) => call.method.contains('request')), isEmpty);
    },
  );

  test('missing settings handler returns failure without throwing', () async {
    expect(await NotificationService().openSettings(), false);
  });

  test('settings platform failure returns failure without throwing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, (_) async {
          throw PlatformException(code: 'unavailable');
        });
    expect(await NotificationService().openSettings(), false);
  });

  test('startup and repeated status checks never request permission', () async {
    final service = NotificationService();
    await service.init();
    expect(await service.access(), NotificationAccess.disabled);
    expect(await service.access(), NotificationAccess.disabled);
    expect(calls.where((c) => c.method.contains('request')), isEmpty);
    expect(calls.where((c) => c.method == 'initialize'), hasLength(1));
  });

  test('explicit request reports denial and can be accepted later', () async {
    final service = NotificationService();
    expect(await service.requestPermissions(), NotificationAccess.disabled);
    grantOnRequest = true;
    expect(await service.requestPermissions(), NotificationAccess.enabled);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      hasLength(2),
    );
  });

  test(
    'granted permission is not requested again; revocation is read live',
    () async {
      final service = NotificationService();
      enabled = true;
      expect(await service.requestPermissions(), NotificationAccess.enabled);
      enabled = false;
      expect(await service.access(), NotificationAccess.disabled);
      enabled = true;
      expect(await service.access(), NotificationAccess.enabled);
      expect(calls.where((c) => c.method.contains('request')), isEmpty);
    },
  );

  test('disabled Android reminder channel is detected', () async {
    enabled = true;
    blockedChannel = true;
    expect(await NotificationService().access(), NotificationAccess.disabled);
  });

  test('plugin failure does not escape and initialisation can retry', () async {
    final service = NotificationService();
    fail = true;
    expect(await service.requestPermissions(), NotificationAccess.unavailable);
    fail = false;
    enabled = true;
    expect(await service.access(), NotificationAccess.enabled);
  });

  test('unsupported platform does not touch the notification plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(
      await NotificationService().requestPermissions(),
      NotificationAccess.unsupported,
    );
    expect(calls, isEmpty);
  });

  test(
    'Darwin initialisation explicitly disables all permission prompts',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      IOSFlutterLocalNotificationsPlugin.registerWith();
      await NotificationService().init();
      final settings =
          calls.singleWhere((c) => c.method == 'initialize').arguments as Map;
      expect(settings['requestAlertPermission'], false);
      expect(settings['requestBadgePermission'], false);
      expect(settings['requestSoundPermission'], false);
      expect(calls.where((c) => c.method == 'requestPermissions'), isEmpty);
    },
  );
}
