import 'dart:ui' as ui;

import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../models/entities.dart';
import 'notification_service.dart';

class AlarmScheduler {
  AlarmScheduler({
    required this.database,
    required this.notifications,
    this.scheduleHorizonDays = 14,
  });

  final AppDatabase database;
  final NotificationService notifications;
  final int scheduleHorizonDays;

  Future<void> seedForPlan(MedicationPlan plan, {DateTime? fromUtc}) async {
    if (plan.medication.kind == MedicationKind.oneTime) {
      final exists = await database.hasAnyAlarmForSchedule(plan.schedule.id);
      if (exists) {
        return;
      }
    }

    final intervalDays = plan.medication.kind == MedicationKind.interval
        ? plan.medication.intervalDays
        : 1;
    final occurrenceCount = plan.medication.kind == MedicationKind.oneTime
        ? 1
        : (scheduleHorizonDays / intervalDays).ceil();

    final occurrences = _generateDeviceLocalOccurrences(
      hour: plan.schedule.hour,
      minute: plan.schedule.minute,
      fromLocal: (fromUtc ?? DateTime.now().toUtc()).toLocal(),
      occurrences: occurrenceCount,
      everyDays: intervalDays,
    );

    for (final occurrence in occurrences) {
      final triggerUtc = occurrence.toUtc();
      final exists = await database.hasPendingAlarmForScheduleAt(
        scheduleId: plan.schedule.id,
        triggerAtUtc: triggerUtc,
      );
      if (exists) {
        continue;
      }

      final alarmId = await database.createAlarmInstance(
        medicationId: plan.medication.id,
        scheduleId: plan.schedule.id,
        triggerAtUtc: triggerUtc,
      );

      await notifications.scheduleAlarm(
        alarmId: alarmId,
        title: _text(
          english: 'Medication time',
          arabic: 'موعد الدواء',
        ),
        body: '${plan.medication.name} • ${plan.medication.dosage}',
        when: tz.TZDateTime.from(occurrence, tz.UTC),
      );
    }
  }

  Future<void> reconcileOnStartup() async {
    await database.markMissedBefore(
      DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
    );

    final plans = await database.getMedicationPlans();
    for (final plan in plans) {
      await seedForPlan(plan);
    }

    final pendingIds = await notifications.getPendingNotificationIds();
    final pendingAlarms = await database.getPendingAlarmInstances();

    for (final alarm in pendingAlarms) {
      if (alarm.triggerAt.isBefore(DateTime.now().toUtc())) {
        continue;
      }
      if (pendingIds.contains(alarm.id)) {
        continue;
      }

      final full = await database.getAlarmWithMedication(alarm.id);
      if (full == null) {
        continue;
      }
      await notifications.scheduleAlarm(
        alarmId: alarm.id,
        title: _text(
          english: 'Medication time',
          arabic: 'موعد الدواء',
        ),
        body: '${full.medication.name} • ${full.medication.dosage}',
        when: tz.TZDateTime.from(alarm.triggerAt.toLocal(), tz.UTC),
      );
    }
  }

  Future<void> markTaken(int alarmId) async {
    final full = await database.getAlarmWithMedication(alarmId);
    if (full == null) {
      return;
    }
    await notifications.cancelAlarm(alarmId);
    await database.updateAlarmStatus(alarmId, AlarmStatus.taken);
    await database.insertDoseLog(
      medicationId: full.medication.id,
      alarmInstanceId: alarmId,
      action: 'taken',
    );
  }

  Future<void> markSkipped(int alarmId) async {
    final full = await database.getAlarmWithMedication(alarmId);
    if (full == null) {
      return;
    }
    await notifications.cancelAlarm(alarmId);
    await database.updateAlarmStatus(alarmId, AlarmStatus.skipped);
    await database.insertDoseLog(
      medicationId: full.medication.id,
      alarmInstanceId: alarmId,
      action: 'skipped',
    );
  }

  Future<void> snooze({required int alarmId, int minutes = 10}) async {
    final full = await database.getAlarmWithMedication(alarmId);
    if (full == null) {
      return;
    }

    await notifications.cancelAlarm(alarmId);
    await database.updateAlarmStatus(alarmId, AlarmStatus.snoozed);
    await database.insertDoseLog(
      medicationId: full.medication.id,
      alarmInstanceId: alarmId,
      action: 'snoozed_${minutes}m',
    );

    final triggerUtc = DateTime.now().toUtc().add(Duration(minutes: minutes));
    final newAlarmId = await database.createAlarmInstance(
      medicationId: full.medication.id,
      scheduleId: full.alarm.scheduleId,
      triggerAtUtc: triggerUtc,
    );

    await notifications.scheduleAlarm(
      alarmId: newAlarmId,
      title: _text(
        english: 'Snoozed medication alarm',
        arabic: 'منبه دواء مؤجل',
      ),
      body: '${full.medication.name} • ${full.medication.dosage}',
      when: tz.TZDateTime.from(triggerUtc.toLocal(), tz.UTC),
    );
  }

  String _text({required String english, required String arabic}) {
    // Notification scheduling runs outside widget context, so we use
    // platform locale directly instead of AppLocalizations here.
    final languageCode = ui.PlatformDispatcher.instance.locale.languageCode;
    return languageCode == 'ar' ? arabic : english;
  }

  List<DateTime> _generateDeviceLocalOccurrences({
    required int hour,
    required int minute,
    required DateTime fromLocal,
    required int occurrences,
    int everyDays = 1,
  }) {
    final normalizedEveryDays = everyDays < 1 ? 1 : everyDays;
    var cursor = DateTime(
      fromLocal.year,
      fromLocal.month,
      fromLocal.day,
      hour,
      minute,
    );

    if (!cursor.isAfter(fromLocal)) {
      cursor = cursor.add(Duration(days: normalizedEveryDays));
      cursor = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        hour,
        minute,
      );
    }

    final dates = <DateTime>[];
    for (var i = 0; i < occurrences; i++) {
      final day = cursor.add(Duration(days: i * normalizedEveryDays));
      dates.add(DateTime(day.year, day.month, day.day, hour, minute));
    }
    return dates;
  }
}
