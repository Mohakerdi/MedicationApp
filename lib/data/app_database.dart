import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/entities.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;
  bool _ffiInitialized = false;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _configureFactoryForDesktop();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'medication_alarm.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  void _configureFactoryForDesktop() {
    if (_ffiInitialized || kIsWeb) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux) {
      return;
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _ffiInitialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'daily',
        interval_days INTEGER NOT NULL DEFAULT 1,
        total_pills INTEGER NOT NULL DEFAULT 0,
        taken_pills INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        timezone_name TEXT NOT NULL,
        FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE alarm_instances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        schedule_id INTEGER NOT NULL,
        trigger_at TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE,
        FOREIGN KEY(schedule_id) REFERENCES dose_schedules(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        alarm_instance_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        acted_at TEXT NOT NULL,
        FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE,
        FOREIGN KEY(alarm_instance_id) REFERENCES alarm_instances(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE medications ADD COLUMN kind TEXT NOT NULL DEFAULT 'daily'",
      );
      await db.execute(
        'ALTER TABLE medications ADD COLUMN interval_days INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE medications ADD COLUMN total_pills INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE medications ADD COLUMN taken_pills INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<MedicationPlan> createMedicationPlan({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    required String timezoneName,
    MedicationKind kind = MedicationKind.daily,
    int intervalDays = 1,
    int totalPills = 0,
  }) async {
    final plans = await createMedicationPlans(
      name: name,
      dosage: dosage,
      times: [(hour: hour, minute: minute)],
      timezoneName: timezoneName,
      kind: kind,
      intervalDays: intervalDays,
      totalPills: totalPills,
    );
    return plans.first;
  }

  Future<List<MedicationPlan>> createMedicationPlans({
    required String name,
    required String dosage,
    required List<({int hour, int minute})> times,
    required String timezoneName,
    MedicationKind kind = MedicationKind.daily,
    int intervalDays = 1,
    int totalPills = 0,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      final medicationId = await txn.insert(
        'medications',
        {
          'name': name,
          'dosage': dosage,
          'kind': kind.value,
          'interval_days': intervalDays < 1 ? 1 : intervalDays,
          'total_pills': totalPills < 0 ? 0 : totalPills,
          'taken_pills': 0,
          'is_active': 1,
          'created_at': now,
        },
      );

      final medication = Medication(
        id: medicationId,
        name: name,
        dosage: dosage,
        kind: kind,
        intervalDays: intervalDays < 1 ? 1 : intervalDays,
        totalPills: totalPills < 0 ? 0 : totalPills,
        takenPills: 0,
        isActive: true,
        createdAt: DateTime.parse(now),
      );

      final plans = <MedicationPlan>[];
      for (final time in times) {
        final scheduleId = await txn.insert(
          'dose_schedules',
          {
            'medication_id': medicationId,
            'hour': time.hour,
            'minute': time.minute,
            'timezone_name': timezoneName,
          },
        );
        plans.add(
          MedicationPlan(
            medication: medication,
            schedule: DoseSchedule(
              id: scheduleId,
              medicationId: medicationId,
              hour: time.hour,
              minute: time.minute,
              timezoneName: timezoneName,
            ),
          ),
        );
      }
      return plans;
    });
  }

  Future<List<MedicationPlan>> getMedicationPlans() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        m.id AS m_id,
        m.name AS m_name,
        m.dosage AS m_dosage,
        m.kind AS m_kind,
        m.interval_days AS m_interval_days,
        m.total_pills AS m_total_pills,
        m.taken_pills AS m_taken_pills,
        m.is_active AS m_is_active,
        m.created_at AS m_created_at,
        s.id AS s_id,
        s.medication_id AS s_medication_id,
        s.hour AS s_hour,
        s.minute AS s_minute,
        s.timezone_name AS s_timezone_name
      FROM medications m
      INNER JOIN dose_schedules s ON s.medication_id = m.id
      WHERE m.is_active = 1
      ORDER BY m.created_at DESC
    ''');

    return rows
        .map(
          (row) => MedicationPlan(
            medication: Medication(
              id: row['m_id'] as int,
              name: row['m_name'] as String,
              dosage: row['m_dosage'] as String,
              kind: MedicationKindValue.fromValue(row['m_kind'] as String),
              intervalDays: row['m_interval_days'] as int,
              totalPills: row['m_total_pills'] as int,
              takenPills: row['m_taken_pills'] as int,
              isActive: (row['m_is_active'] as int) == 1,
              createdAt: DateTime.parse(row['m_created_at'] as String),
            ),
            schedule: DoseSchedule(
              id: row['s_id'] as int,
              medicationId: row['s_medication_id'] as int,
              hour: row['s_hour'] as int,
              minute: row['s_minute'] as int,
              timezoneName: row['s_timezone_name'] as String,
            ),
          ),
        )
        .toList();
  }

  Future<int> createAlarmInstance({
    required int medicationId,
    required int scheduleId,
    required DateTime triggerAtUtc,
    AlarmStatus status = AlarmStatus.pending,
  }) async {
    final db = await database;
    return db.insert(
      'alarm_instances',
      {
        'medication_id': medicationId,
        'schedule_id': scheduleId,
        'trigger_at': triggerAtUtc.toIso8601String(),
        'status': status.value,
      },
    );
  }

  Future<void> updateAlarmStatus(int alarmId, AlarmStatus status) async {
    final db = await database;
    await db.update(
      'alarm_instances',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [alarmId],
    );
  }

  Future<void> insertDoseLog({
    required int medicationId,
    required int alarmInstanceId,
    required String action,
    DateTime? actedAt,
  }) async {
    final db = await database;
    await db.insert(
      'dose_logs',
      {
        'medication_id': medicationId,
        'alarm_instance_id': alarmInstanceId,
        'action': action,
        'acted_at': (actedAt ?? DateTime.now().toUtc()).toIso8601String(),
      },
    );
  }

  Future<AlarmWithMedication?> getAlarmWithMedication(int alarmId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        a.id AS a_id,
        a.medication_id AS a_medication_id,
        a.schedule_id AS a_schedule_id,
        a.trigger_at AS a_trigger_at,
        a.status AS a_status,
        m.id AS m_id,
        m.name AS m_name,
        m.dosage AS m_dosage,
        m.kind AS m_kind,
        m.interval_days AS m_interval_days,
        m.total_pills AS m_total_pills,
        m.taken_pills AS m_taken_pills,
        m.is_active AS m_is_active,
        m.created_at AS m_created_at
      FROM alarm_instances a
      INNER JOIN medications m ON m.id = a.medication_id
      WHERE a.id = ?
      LIMIT 1
    ''', [alarmId]);

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return AlarmWithMedication(
      alarm: AlarmInstance(
        id: row['a_id'] as int,
        medicationId: row['a_medication_id'] as int,
        scheduleId: row['a_schedule_id'] as int,
        triggerAt: DateTime.parse(row['a_trigger_at'] as String),
        status: AlarmStatusValue.fromValue(row['a_status'] as String),
      ),
      medication: Medication(
        id: row['m_id'] as int,
        name: row['m_name'] as String,
        dosage: row['m_dosage'] as String,
        kind: MedicationKindValue.fromValue(row['m_kind'] as String),
        intervalDays: row['m_interval_days'] as int,
        totalPills: row['m_total_pills'] as int,
        takenPills: row['m_taken_pills'] as int,
        isActive: (row['m_is_active'] as int) == 1,
        createdAt: DateTime.parse(row['m_created_at'] as String),
      ),
    );
  }

  Future<List<AlarmInstance>> getPendingAlarmInstances() async {
    final db = await database;
    final rows = await db.query(
      'alarm_instances',
      where: 'status = ?',
      whereArgs: [AlarmStatus.pending.value],
      orderBy: 'trigger_at ASC',
    );
    return rows.map(AlarmInstance.fromMap).toList();
  }

  Future<void> markMissedBefore(DateTime beforeUtc) async {
    final db = await database;
    final candidates = await db.query(
      'alarm_instances',
      where: 'status = ? AND trigger_at < ?',
      whereArgs: [AlarmStatus.pending.value, beforeUtc.toIso8601String()],
    );

    await db.transaction((txn) async {
      for (final row in candidates) {
        final alarmId = row['id'] as int;
        final medicationId = row['medication_id'] as int;
        await txn.update(
          'alarm_instances',
          {'status': AlarmStatus.missed.value},
          where: 'id = ?',
          whereArgs: [alarmId],
        );
        await txn.insert(
          'dose_logs',
          {
            'medication_id': medicationId,
            'alarm_instance_id': alarmId,
            'action': 'missed',
            'acted_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
    });
  }

  Future<bool> hasPendingAlarmForScheduleAt({
    required int scheduleId,
    required DateTime triggerAtUtc,
  }) async {
    final db = await database;
    final rows = await db.query(
      'alarm_instances',
      columns: ['id'],
      where: 'schedule_id = ? AND trigger_at = ? AND status = ?',
      whereArgs: [
        scheduleId,
        triggerAtUtc.toIso8601String(),
        AlarmStatus.pending.value,
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasAnyAlarmForSchedule(int scheduleId) async {
    final db = await database;
    final rows = await db.query(
      'alarm_instances',
      columns: ['id'],
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<MedicationPlan>> getMedicationPlansByMedicationId(
    int medicationId,
  ) async {
    final plans = await getMedicationPlans();
    return plans.where((plan) => plan.medication.id == medicationId).toList();
  }

  Future<void> updateDoseScheduleTime({
    required int scheduleId,
    required int hour,
    required int minute,
  }) async {
    final db = await database;
    await db.update(
      'dose_schedules',
      {
        'hour': hour,
        'minute': minute,
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<void> dismissPendingAlarmsForSchedule({
    required int scheduleId,
    required String action,
  }) async {
    final db = await database;
    final rows = await db.query(
      'alarm_instances',
      where: 'schedule_id = ? AND status = ?',
      whereArgs: [scheduleId, AlarmStatus.pending.value],
    );
    if (rows.isEmpty) {
      return;
    }

    await db.transaction((txn) async {
      for (final row in rows) {
        final alarmId = row['id'] as int;
        final medicationId = row['medication_id'] as int;
        await txn.update(
          'alarm_instances',
          {'status': AlarmStatus.skipped.value},
          where: 'id = ?',
          whereArgs: [alarmId],
        );
        await txn.insert(
          'dose_logs',
          {
            'medication_id': medicationId,
            'alarm_instance_id': alarmId,
            'action': action,
            'acted_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
    });
  }

  Future<List<int>> getPendingAlarmIdsForSchedule(int scheduleId) async {
    final db = await database;
    final rows = await db.query(
      'alarm_instances',
      columns: ['id'],
      where: 'schedule_id = ? AND status = ?',
      whereArgs: [scheduleId, AlarmStatus.pending.value],
    );
    return rows.map((row) => row['id'] as int).toList();
  }

  Future<void> deleteDoseSchedule(int scheduleId) async {
    final db = await database;
    await db.transaction((txn) async {
      final scheduleRows = await txn.query(
        'dose_schedules',
        columns: ['medication_id'],
        where: 'id = ?',
        whereArgs: [scheduleId],
        limit: 1,
      );
      if (scheduleRows.isEmpty) {
        return;
      }
      final medicationId = scheduleRows.first['medication_id'] as int;
      await txn.delete(
        'dose_schedules',
        where: 'id = ?',
        whereArgs: [scheduleId],
      );
      final remaining = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM dose_schedules WHERE medication_id = ?',
          [medicationId],
        ),
      );
      if ((remaining ?? 0) == 0) {
        await txn.update(
          'medications',
          {'is_active': 0},
          where: 'id = ?',
          whereArgs: [medicationId],
        );
      }
    });
  }

  Future<void> incrementMedicationTakenPills(int medicationId) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'medications',
        columns: ['total_pills', 'taken_pills'],
        where: 'id = ?',
        whereArgs: [medicationId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return;
      }
      final totalPills = rows.first['total_pills'] as int;
      final currentTaken = rows.first['taken_pills'] as int;
      final nextTaken = currentTaken + 1 > totalPills ? totalPills : currentTaken + 1;
      await txn.update(
        'medications',
        {
          'taken_pills': nextTaken,
          if (totalPills > 0 && nextTaken >= totalPills) 'is_active': 0,
        },
        where: 'id = ?',
        whereArgs: [medicationId],
      );
    });
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('dose_logs');
      await txn.delete('alarm_instances');
      await txn.delete('dose_schedules');
      await txn.delete('medications');
    });
  }
}
