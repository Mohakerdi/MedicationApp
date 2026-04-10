import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/alarm_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService.instance;
  int? initialAlarmId;
  try {
    initialAlarmId = await notifications.initialize();
  } catch (_) {
    initialAlarmId = null;
  }
  final database = AppDatabase.instance;
  final scheduler = AlarmScheduler(database: database, notifications: notifications);

  runApp(
    MedicationApp(
      database: database,
      notifications: notifications,
      scheduler: scheduler,
      initialAlarmId: initialAlarmId,
    ),
  );
}
