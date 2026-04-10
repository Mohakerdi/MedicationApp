import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<int> _alarmSelectionController =
      StreamController<int>.broadcast();

  Stream<int> get alarmSelectionStream => _alarmSelectionController.stream;

  Future<int?> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    await _createAndroidChannels();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    return _extractAlarmId(payload);
  }

  Future<void> _createAndroidChannels() async {
    final androidPlatform =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlatform == null) {
      return;
    }

    await androidPlatform.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_alarm_channel',
        'Medication alarms',
        description: 'Exact, full-screen alarms for medication reminders',
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  Future<void> requestUserPermissions() async {
    final androidPlatform =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.requestNotificationsPermission();
    await androidPlatform?.requestExactAlarmsPermission();
    await androidPlatform?.requestFullScreenIntentPermission();

    final iosPlatform =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> canScheduleExactAlarms() async {
    final androidPlatform =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlatform == null) {
      return true;
    }
    return await androidPlatform.canScheduleExactNotifications() ?? false;
  }

  Future<void> scheduleAlarm({
    required int alarmId,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_alarm_channel',
      'Medication alarms',
      channelDescription: 'Exact, full-screen alarms for medication reminders',
      category: AndroidNotificationCategory.alarm,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      ticker: 'Medication alarm',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.zonedSchedule(
      alarmId,
      title,
      body,
      when,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'alarm:$alarmId',
    );
  }

  Future<void> cancelAlarm(int alarmId) {
    return _plugin.cancel(alarmId);
  }

  Future<Set<int>> getPendingNotificationIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((item) => item.id).toSet();
  }

  void _onNotificationResponse(NotificationResponse response) {
    final alarmId = _extractAlarmId(response.payload);
    if (alarmId != null) {
      _alarmSelectionController.add(alarmId);
    }
  }

  static int? _extractAlarmId(String? payload) {
    if (payload == null || !payload.startsWith('alarm:')) {
      return null;
    }
    return int.tryParse(payload.split(':').last);
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  // Handled when app returns to foreground.
}
