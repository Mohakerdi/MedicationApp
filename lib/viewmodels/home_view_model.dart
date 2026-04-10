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
    required List<({int hour, int minute})> times,
    required MedicationKind kind,
    required int intervalDays,
    required int totalPills,
  }) async {
    final timezoneName = _resolveTimezoneName();
    final plans = await database.createMedicationPlans(
      name: name.trim(),
      dosage: dosage.trim(),
      times: times,
      timezoneName: timezoneName,
      kind: kind,
      intervalDays: intervalDays,
      totalPills: totalPills,
    );
    for (final plan in plans) {
      await scheduler.seedForPlan(plan);
    }
    await load();
  }

  String _resolveTimezoneName() {
    try {
      return tz.local.name;
    } catch (_) {
      final localName = DateTime.now().timeZoneName.trim();
      return localName.isEmpty ? 'UTC' : localName;
    }
  }

  Future<AlarmWithMedication?> getAlarmById(int alarmId) {
    return database.getAlarmWithMedication(alarmId);
  }

  Future<AlarmWithMedication?> getDueAlarmForImmediateDisplay({
    Duration lookback = const Duration(minutes: 1),
    Duration lookahead = const Duration(seconds: 30),
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final pending = await database.getPendingAlarmInstances();
    pending.sort((a, b) => a.triggerAt.compareTo(b.triggerAt));

    for (final alarm in pending) {
      if (alarm.triggerAt.isAfter(nowUtc.add(lookahead))) {
        break;
      }
      if (alarm.triggerAt.isBefore(nowUtc.subtract(lookback))) {
        continue;
      }
      final full = await database.getAlarmWithMedication(alarm.id);
      if (full != null) {
        return full;
      }
    }
    return null;
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

  Future<void> dismissScheduleBySwipe(MedicationPlan plan) async {
    final alarmIds = await database.getPendingAlarmIdsForSchedule(plan.schedule.id);
    for (final id in alarmIds) {
      await notifications.cancelAlarm(id);
    }
    await database.dismissPendingAlarmsForSchedule(
      scheduleId: plan.schedule.id,
      action: 'dismissed_by_swipe',
    );
    await database.deleteDoseSchedule(plan.schedule.id);
    await load();
  }

  Future<void> editScheduleTime({
    required MedicationPlan plan,
    required int hour,
    required int minute,
  }) async {
    final alarmIds = await database.getPendingAlarmIdsForSchedule(plan.schedule.id);
    for (final id in alarmIds) {
      await notifications.cancelAlarm(id);
    }
    await database.dismissPendingAlarmsForSchedule(
      scheduleId: plan.schedule.id,
      action: 'dismissed_by_edit',
    );
    await database.updateDoseScheduleTime(
      scheduleId: plan.schedule.id,
      hour: hour,
      minute: minute,
    );
    final refreshedPlans = await database.getMedicationPlansByMedicationId(
      plan.medication.id,
    );
    final edited = refreshedPlans.firstWhere(
      (item) => item.schedule.id == plan.schedule.id,
      orElse: () => plan,
    );
    await scheduler.seedForPlan(edited);
    await load();
  }

  Future<void> markOneTimePillTaken(int medicationId) async {
    await database.incrementMedicationTakenPills(medicationId);
    await load();
  }

  Future<void> deleteAllData() async {
    await notifications.cancelAll();
    await database.deleteAllData();
    await load();
  }
}
