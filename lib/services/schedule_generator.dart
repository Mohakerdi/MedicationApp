import 'package:timezone/timezone.dart' as tz;

class ScheduleGenerator {
  static List<tz.TZDateTime> generateOccurrences({
    required tz.Location location,
    required int hour,
    required int minute,
    required DateTime fromUtc,
    required int occurrences,
    int everyDays = 1,
  }) {
    final normalizedEveryDays = everyDays < 1 ? 1 : everyDays;
    final fromLocal = tz.TZDateTime.from(fromUtc, location);
    var cursor = tz.TZDateTime(
      location,
      fromLocal.year,
      fromLocal.month,
      fromLocal.day,
      hour,
      minute,
    );

    if (!cursor.isAfter(fromLocal)) {
      cursor = cursor.add(Duration(days: normalizedEveryDays));
      cursor = tz.TZDateTime(
        location,
        cursor.year,
        cursor.month,
        cursor.day,
        hour,
        minute,
      );
    }

    final dates = <tz.TZDateTime>[];
    for (var i = 0; i < occurrences; i++) {
      final day = cursor.add(Duration(days: i * normalizedEveryDays));
      final next = tz.TZDateTime(
        location,
        day.year,
        day.month,
        day.day,
        hour,
        minute,
      );
      dates.add(next);
    }
    return dates;
  }

  static List<tz.TZDateTime> generateDailyOccurrences({
    required tz.Location location,
    required int hour,
    required int minute,
    required DateTime fromUtc,
    required int days,
  }) {
    return generateOccurrences(
      location: location,
      hour: hour,
      minute: minute,
      fromUtc: fromUtc,
      occurrences: days,
      everyDays: 1,
    );
  }
}
