import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/alarm_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService.instance;
  try {
    await notifications.initialize();
  } catch (_) {
    // Ignore initialization errors and continue app startup.
  }
  unawaited(
    notifications.requestUserPermissions().catchError((error, _) {
      debugPrint(
        'Request notification/alarm permissions failed: ${error.toString()}',
      );
    }),
  );
  final database = AppDatabase.instance;
  final scheduler = AlarmScheduler(database: database, notifications: notifications);

  runApp(
    MedicationApp(
      database: database,
      notifications: notifications,
      scheduler: scheduler,
    ),
  );
}
