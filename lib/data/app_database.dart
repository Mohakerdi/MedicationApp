import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/entities.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'medication_alarm.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
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

  Future<MedicationPlan> createMedicationPlan({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    required String timezoneName,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      final medicationId = await txn.insert(
        'medications',
        {
          'name': name,
          'dosage': dosage,
          'is_active': 1,
          'created_at': now,
        },
      );

      final scheduleId = await txn.insert(
        'dose_schedules',
        {
          'medication_id': medicationId,
          'hour': hour,
          'minute': minute,
          'timezone_name': timezoneName,
        },
      );

      return MedicationPlan(
        medication: Medication(
          id: medicationId,
          name: name,
          dosage: dosage,
          isActive: true,
          createdAt: DateTime.parse(now),
        ),
        schedule: DoseSchedule(
          id: scheduleId,
          medicationId: medicationId,
          hour: hour,
          minute: minute,
          timezoneName: timezoneName,
        ),
      );
    });
  }

  Future<List<MedicationPlan>> getMedicationPlans() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        m.id AS m_id,
        m.name AS m_name,
        m.dosage AS m_dosage,
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
}
