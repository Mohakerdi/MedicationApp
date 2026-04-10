import 'app.dart';
import 'data/app_database.dart';
import 'services/alarm_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService.instance;
  final initialAlarmId = await notifications.initialize();
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
