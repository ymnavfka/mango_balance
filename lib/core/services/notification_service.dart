import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Обёртка над локальными уведомлениями: инициализация, разрешения и
/// планирование/отмена. Работает на Android, iOS и macOS; на остальных
/// платформах методы — no-op.
enum NotificationAccess { enabled, disabled, unavailable, unsupported }

class NotificationService {
  static const _settingsChannel = MethodChannel(
    'mango_balance/notification_settings',
  );
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void>? _initializing;

  static const _channelId = 'recurring_reminders';
  static const _channelName = 'Напоминания о платежах';
  static const _channelDescription =
      'Оповещения о предстоящих регулярных платежах';

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (!_supported || _ready) return;
    final pending = _initializing ??= _initialize();
    try {
      await pending;
    } finally {
      if (identical(_initializing, pending)) _initializing = null;
    }
  }

  Future<void> _initialize() async {
    if (!_supported || _ready) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Если зону определить не удалось — остаётся значение по умолчанию.
    }

    // Маленькая иконка должна быть монохромной (по альфа-каналу) — берём силуэт
    // логотипа из переднего плана адаптивной иконки, иначе цветной ic_launcher
    // превращается в белый квадрат.
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher_foreground',
    );
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    _ready = true;
  }

  /// Всегда читаем системные настройки: сохранённый флаг устаревает после
  /// ручного отзыва разрешения. Проверка сама не показывает диалог.
  Future<NotificationAccess> access() async {
    if (!_supported) return NotificationAccess.unsupported;
    try {
      await init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        if (enabled == null) return NotificationAccess.unavailable;
        if (!enabled) return NotificationAccess.disabled;
        final channels = await android.getNotificationChannels();
        if (channels != null &&
            channels.any(
              (c) => c.id == _channelId && c.importance == Importance.none,
            )) {
          return NotificationAccess.disabled;
        }
        return NotificationAccess.enabled;
      }
      final options =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.checkPermissions() ??
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.checkPermissions();
      if (options == null) return NotificationAccess.unavailable;
      return options.isEnabled || options.isProvisionalEnabled
          ? NotificationAccess.enabled
          : NotificationAccess.disabled;
    } catch (_) {
      return NotificationAccess.unavailable;
    }
  }

  /// Вызывать только после явного создания платежа с оповещением.
  /// Отказ/закрытие диалога не считаются ошибкой сохранения платежа.
  Future<NotificationAccess> requestPermissions() async {
    final current = await access();
    if (current != NotificationAccess.disabled) return current;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return await access();
    } catch (_) {
      return NotificationAccess.unavailable;
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  Future<bool> openSettings() async {
    if (!_supported) return false;
    try {
      return await _settingsChannel.invokeMethod<bool>(
            'openNotificationSettings',
            {'channelId': _channelId},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  /// Планирует уведомление на [when]. Если время в прошлом — ничего не делает.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) return;
    if (!when.isAfter(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          // Маленькая (статус-бар) — монохромный силуэт логотипа; большая
          // (в теле уведомления) — цветная иконка приложения.
          icon: '@mipmap/ic_launcher_foreground',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}
