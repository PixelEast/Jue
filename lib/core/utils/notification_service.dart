import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'decision_reminder';
  static const String _channelName = '决定提醒';

  Future<bool> init() async {
    if (_initialized) return true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final result = await _plugin.initialize(initSettings);
    _initialized = result ?? false;

    if (_initialized) {
      await _createNotificationChannel();
    }

    return _initialized;
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '根据你的使用习惯提醒你执行决定',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> checkPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  static const List<String> _bodyTexts = [
    '「%s」判决时刻已至.',
    '是时候对「%s」作出判决了.',
    '「%s」等待你的判决.',
  ];

  Future<void> showReminderNotification({
    required int id,
    required String decisionTheme,
    required String decisionId,
  }) async {
    if (!_initialized) return;

    final random = Random();
    final bodyTemplate = _bodyTexts[random.nextInt(_bodyTexts.length)];
    final body = bodyTemplate.replaceAll('%s', decisionTheme);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '根据你的使用习惯提醒你执行决定',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/notification_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '即刻判决',
      ),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      '即刻判决',
      body,
      details,
      payload: decisionId,
    );
  }

  Future<void> scheduleCheck() async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = _nextCheckTime(now);

    await _plugin.zonedSchedule(
      0,
      '',
      '',
      scheduledDate,
      const NotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  tz.TZDateTime _nextCheckTime(tz.TZDateTime from) {
    var scheduled = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      from.hour,
      (from.minute ~/ 30 + 1) * 30,
    );
    if (scheduled.isBefore(from)) {
      scheduled = scheduled.add(const Duration(minutes: 30));
    }
    return scheduled;
  }
}
