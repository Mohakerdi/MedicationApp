import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import 'app_settings_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (!_supportsNotificationScheduling) {
      return;
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
      );

      await _createAndroidDefaultChannel();
    } catch (error) {
      debugPrint('Notification initialize failed: ${error.toString()}');
    }
  }

  Future<void> _createAndroidDefaultChannel() async {
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
        description: 'Exact medication reminder notifications',
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
    String? soundId,
  }) async {
    if (!_supportsNotificationScheduling) {
      return;
    }
    final alarmSound = await _resolveAlarmSound(soundId);
    final channelId = _channelIdForSound(alarmSound.id);
    final androidSound = _androidSoundFor(alarmSound);

    await _ensureAndroidChannel(
      channelId: channelId,
      androidSound: androidSound,
      soundLabel: alarmSound.label,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Medication alarms',
      channelDescription: 'Exact medication reminder notifications',
      category: AndroidNotificationCategory.alarm,
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: true,
      playSound: true,
      sound: androidSound,
      visibility: NotificationVisibility.public,
      ticker: 'Medication alarm',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      sound: _darwinSoundNameFor(alarmSound),
    );

    try {
      await _plugin.zonedSchedule(
        alarmId,
        title,
        body,
        when,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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
    // No in-app popup handling. Notification taps open the app normally.
  }

  Future<AppAlarmSound> _resolveAlarmSound(String? soundId) async {
    var resolvedSoundId = soundId;
    if (resolvedSoundId == null || resolvedSoundId.trim().isEmpty) {
      final settings = await AppSettingsService().load();
      resolvedSoundId = settings.selectedSoundId;
    }

    for (final sound in defaultAlarmSounds) {
      if (sound.id == resolvedSoundId) {
        return sound;
      }
    }
    if (resolvedSoundId.startsWith('device:')) {
      final path = resolvedSoundId.replaceFirst('device:', '');
      if (path.isNotEmpty) {
        return AppAlarmSound(
          id: resolvedSoundId,
          label: 'Device sound',
          type: AppAlarmSoundType.device,
          path: path,
        );
      }
    }
    return defaultAlarmSounds.first;
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

  AndroidNotificationSound? _androidSoundFor(AppAlarmSound sound) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    if (sound.isAsset) {
      return RawResourceAndroidNotificationSound(
        p.basenameWithoutExtension(sound.path),
      );
    }
    return UriAndroidNotificationSound(Uri.file(sound.path).toString());
  }

  String? _darwinSoundNameFor(AppAlarmSound sound) {
    if (!sound.isAsset) {
      return null;
    }
    return p.basename(sound.path);
  }

  String _channelIdForSound(String soundId) {
    final hash = soundId.codeUnits.fold<int>(
      0,
      (value, unit) => (value * 31 + unit) & 0x3fffffff,
    );
    return 'medication_alarm_channel_$hash';
  }

  Future<void> _ensureAndroidChannel({
    required String channelId,
    required AndroidNotificationSound? androidSound,
    required String soundLabel,
  }) async {
    final androidPlatform =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlatform == null) {
      return;
    }
    await androidPlatform.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'Medication alarms ($soundLabel)',
        description: 'Exact medication reminder notifications',
        importance: Importance.max,
        playSound: true,
        sound: androidSound,
      ),
    );
  }
}
