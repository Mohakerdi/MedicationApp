import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../models/entities.dart';
import 'notification_service.dart';
import 'schedule_generator.dart';

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
    final location = _safeLocation(plan.schedule.timezoneName);
    final occurrences = ScheduleGenerator.generateDailyOccurrences(
      location: location,
      hour: plan.schedule.hour,
      minute: plan.schedule.minute,
      fromUtc: fromUtc ?? DateTime.now().toUtc(),
      days: scheduleHorizonDays,
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
        title: 'Medication time',
        body: '${plan.medication.name} • ${plan.medication.dosage}',
        when: occurrence,
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
        title: 'Medication time',
        body: '${full.medication.name} • ${full.medication.dosage}',
        when: tz.TZDateTime.from(alarm.triggerAt.toLocal(), tz.local),
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
      title: 'Snoozed medication alarm',
      body: '${full.medication.name} • ${full.medication.dosage}',
      when: tz.TZDateTime.from(triggerUtc.toLocal(), tz.local),
    );
  }

  tz.Location _safeLocation(String timezoneName) {
    try {
      return tz.getLocation(timezoneName);
    } catch (_) {
      return tz.local;
    }
  }
}
