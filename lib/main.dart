import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'screens/home_screen.dart';
import 'services/alarm_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService.instance;
  final initialAlarmId = await notifications.initialize();
  final database = AppDatabase.instance;
  final scheduler = AlarmScheduler(database: database, notifications: notifications);

  runApp(
    MyApp(
      database: database,
      notifications: notifications,
      scheduler: scheduler,
      initialAlarmId: initialAlarmId,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.database,
    required this.notifications,
    required this.scheduler,
    this.initialAlarmId,
  });

  final AppDatabase database;
  final NotificationService notifications;
  final AlarmScheduler scheduler;
  final int? initialAlarmId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medication Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(
        database: database,
        scheduler: scheduler,
        notifications: notifications,
        initialAlarmId: initialAlarmId,
      ),
    );
  }
}
