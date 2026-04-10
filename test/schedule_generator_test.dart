import 'package:flutter_test/flutter_test.dart';
import 'package:medecation_app/services/schedule_generator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  test('generates daily occurrences at same local time', () {
    final location = tz.getLocation('America/New_York');
    final fromUtc = DateTime.utc(2025, 1, 10, 12, 0);

    final items = ScheduleGenerator.generateDailyOccurrences(
      location: location,
      hour: 8,
      minute: 30,
      fromUtc: fromUtc,
      days: 5,
    );

    expect(items.length, 5);
    for (final item in items) {
      expect(item.hour, 8);
      expect(item.minute, 30);
      expect(item.location.name, 'America/New_York');
    }
  });

  test('keeps wall clock hour through DST transition', () {
    final location = tz.getLocation('America/New_York');
    final fromUtc = DateTime.utc(2025, 3, 7, 12, 0);

    final items = ScheduleGenerator.generateDailyOccurrences(
      location: location,
      hour: 8,
      minute: 0,
      fromUtc: fromUtc,
      days: 6,
    );

    expect(items.length, 6);
    for (final item in items) {
      expect(item.hour, 8);
      expect(item.minute, 0);
    }
  });
}
