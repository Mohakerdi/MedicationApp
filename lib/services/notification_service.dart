import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _fullScreenIntentAllowed = false;

  final StreamController<int> _alarmSelectionController =
      StreamController<int>.broadcast();

  Stream<int> get alarmSelectionStream => _alarmSelectionController.stream;

  Future<int?> initialize() async {
    if (!_supportsNotificationScheduling) {
      return null;
    }
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

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            notificationTapBackgroundHandler,
      );

      await _createAndroidChannels();
      _fullScreenIntentAllowed = await _canUseFullScreenIntent();

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final payload = launchDetails?.notificationResponse?.payload;
      return _extractAlarmId(payload);
    } catch (error) {
      debugPrint('Notification initialize failed: ${error.toString()}');
      return null;
    }
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
    if (!_supportsNotificationScheduling) {
      return;
    }
    try {
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
    } catch (error) {
      debugPrint('Notification permission request failed: ${error.toString()}');
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!_supportsNotificationScheduling) {
      return false;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final androidPlatform =
          _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform == null) {
        return true;
      }
      return await androidPlatform.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> scheduleAlarm({
    required int alarmId,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    if (!_supportsNotificationScheduling) {
      return;
    }
    final androidDetails = AndroidNotificationDetails(
      'medication_alarm_channel',
      'Medication alarms',
      channelDescription: 'Exact, full-screen alarms for medication reminders',
      category: AndroidNotificationCategory.alarm,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: _fullScreenIntentAllowed,
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

    try {
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
    } catch (error) {
      debugPrint('Schedule alarm failed for id $alarmId: ${error.toString()}');
    }
  }

  Future<void> cancelAlarm(int alarmId) async {
    if (!_supportsNotificationScheduling) {
      return;
    }
    try {
      await _plugin.cancel(alarmId);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_supportsNotificationScheduling) {
      return;
    }
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<Set<int>> getPendingNotificationIds() async {
    if (!_supportsNotificationScheduling) {
      return {};
    }
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((item) => item.id).toSet();
    } catch (_) {
      return {};
    }
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

  bool get _supportsNotificationScheduling {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<bool> _canUseFullScreenIntent() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final androidPlatform =
          _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform == null) {
        return false;
      }

      // Kept dynamic for compatibility with plugin API versions.
      final dynamic dynamicPlatform = androidPlatform;
      final allowed = await dynamicPlatform.canUseFullScreenIntent();
      return allowed == true;
    } catch (_) {
      return false;
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  // Handled when app returns to foreground.
}
