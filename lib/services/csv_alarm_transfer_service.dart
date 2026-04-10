import '../models/entities.dart';

class AlarmCsvRow {
  const AlarmCsvRow({
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.timezoneName,
  });

  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final String timezoneName;
}

class CsvAlarmTransferService {
  String exportPlans(
    List<MedicationPlan> plans, {
    required List<String> headers,
  }) {
    final lines = <String>[
      headers.map(_escape).join(','),
      ...plans.map(
        (plan) => [
          plan.medication.name,
          plan.medication.dosage,
          plan.schedule.hour.toString(),
          plan.schedule.minute.toString(),
          plan.schedule.timezoneName,
        ].map(_escape).join(','),
      ),
    ];
    return lines.join('\n');
  }

  List<AlarmCsvRow> importRows(String csv) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      return const [];
    }

    final rows = <AlarmCsvRow>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = _parseLine(lines[i]);
      if (cols.length < 5) {
        continue;
      }

      final hour = int.tryParse(cols[2].trim());
      final minute = int.tryParse(cols[3].trim());
      if (hour == null || minute == null) {
        continue;
      }
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        continue;
      }

      final name = cols[0].trim();
      final dosage = cols[1].trim();
      final timezoneName = cols[4].trim();
      if (name.isEmpty || dosage.isEmpty || timezoneName.isEmpty) {
        continue;
      }

      rows.add(
        AlarmCsvRow(
          name: name,
          dosage: dosage,
          hour: hour,
          minute: minute,
          timezoneName: timezoneName,
        ),
      );
    }
    return rows;
  }

  List<String> _parseLine(String line) {
    final out = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i += 2;
          continue;
        }
        inQuotes = !inQuotes;
        i++;
        continue;
      }

      if (char == ',' && !inQuotes) {
        out.add(sb.toString());
        sb.clear();
        i++;
        continue;
      }

      sb.write(char);
      i++;
    }
    out.add(sb.toString());
    return out;
  }

  String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
