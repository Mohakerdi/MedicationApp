import 'package:timezone/timezone.dart' as tz;

class ScheduleGenerator {
  static List<tz.TZDateTime> generateDailyOccurrences({
    required tz.Location location,
    required int hour,
    required int minute,
    required DateTime fromUtc,
    required int days,
  }) {
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
      cursor = cursor.add(const Duration(days: 1));
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
    for (var i = 0; i < days; i++) {
      final day = cursor.add(Duration(days: i));
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
}
