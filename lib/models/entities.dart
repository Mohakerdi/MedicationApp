class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String dosage;
  final bool isActive;
  final DateTime createdAt;

  factory Medication.fromMap(Map<String, Object?> map) {
    return Medication(
      id: map['id'] as int,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class DoseSchedule {
  const DoseSchedule({
    required this.id,
    required this.medicationId,
    required this.hour,
    required this.minute,
    required this.timezoneName,
  });

  final int id;
  final int medicationId;
  final int hour;
  final int minute;
  final String timezoneName;

  factory DoseSchedule.fromMap(Map<String, Object?> map) {
    return DoseSchedule(
      id: map['id'] as int,
      medicationId: map['medication_id'] as int,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      timezoneName: map['timezone_name'] as String,
    );
  }
}

enum AlarmStatus { pending, snoozed, taken, skipped, missed }

extension AlarmStatusValue on AlarmStatus {
  String get value => name;

  static AlarmStatus fromValue(String value) {
    return AlarmStatus.values.firstWhere((status) => status.name == value);
  }
}

class AlarmInstance {
  const AlarmInstance({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.triggerAt,
    required this.status,
  });

  final int id;
  final int medicationId;
  final int scheduleId;
  final DateTime triggerAt;
  final AlarmStatus status;

  factory AlarmInstance.fromMap(Map<String, Object?> map) {
    return AlarmInstance(
      id: map['id'] as int,
      medicationId: map['medication_id'] as int,
      scheduleId: map['schedule_id'] as int,
      triggerAt: DateTime.parse(map['trigger_at'] as String),
      status: AlarmStatusValue.fromValue(map['status'] as String),
    );
  }
}

class AlarmWithMedication {
  const AlarmWithMedication({
    required this.alarm,
    required this.medication,
  });

  final AlarmInstance alarm;
  final Medication medication;
}

class MedicationPlan {
  const MedicationPlan({
    required this.medication,
    required this.schedule,
  });

  final Medication medication;
  final DoseSchedule schedule;
}
