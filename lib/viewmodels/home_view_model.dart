import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../models/entities.dart';
import '../services/alarm_scheduler.dart';
import '../services/csv_alarm_transfer_service.dart';
import '../services/notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this.database,
    required this.scheduler,
    required this.notifications,
    required this.csvService,
  });

  final AppDatabase database;
  final AlarmScheduler scheduler;
  final NotificationService notifications;
  final CsvAlarmTransferService csvService;

  List<MedicationPlan> _plans = const [];
  bool _exactAlarmGranted = true;

  List<MedicationPlan> get plans => _plans;
  bool get exactAlarmGranted => _exactAlarmGranted;

  Future<void> load() async {
    try {
      await scheduler.reconcileOnStartup();
    } catch (_) {}
    final plans = await database.getMedicationPlans();
    bool exact = true;
    try {
      exact = await notifications.canScheduleExactAlarms();
    } catch (_) {}
    _plans = plans;
    _exactAlarmGranted = exact;
    notifyListeners();
  }

  Future<void> addMedication({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    final timezoneName = tz.local.name;
    final plan = await database.createMedicationPlan(
      name: name.trim(),
      dosage: dosage.trim(),
      hour: hour,
      minute: minute,
      timezoneName: timezoneName,
    );
    await scheduler.seedForPlan(plan);
    await load();
  }

  Future<AlarmWithMedication?> getAlarmById(int alarmId) {
    return database.getAlarmWithMedication(alarmId);
  }

  Future<void> requestAlarmPermissions() async {
    await notifications.requestUserPermissions();
    await load();
  }

  Future<String?> exportAsCsv({
    required List<String> headers,
    String filePrefix = 'medication_alarms',
  }) async {
    if (kIsWeb) {
      return null;
    }

    final csv = csvService.exportPlans(_plans, headers: headers);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(dir.path, '$filePrefix$timestamp.csv'));
    await file.writeAsString(csv);
    return file.path;
  }

  Future<int> importFromCsv(String csv) async {
    final rows = csvService.importRows(csv);
    var imported = 0;
    for (final row in rows) {
      final plan = await database.createMedicationPlan(
        name: row.name,
        dosage: row.dosage,
        hour: row.hour,
        minute: row.minute,
        timezoneName: row.timezoneName,
      );
      await scheduler.seedForPlan(plan);
      imported++;
    }
    await load();
    return imported;
  }

  Future<void> deleteAllData() async {
    await notifications.cancelAll();
    await database.deleteAllData();
    await load();
  }
}
