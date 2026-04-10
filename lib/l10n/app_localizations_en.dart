// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mordy';

  @override
  String get exactAlarmsEnabled => 'Exact alarms enabled';

  @override
  String get exactAlarmsDisabled => 'Exact alarms not enabled';

  @override
  String get grantAlarmPermissions => 'Grant Alarm Permissions';

  @override
  String get exactAlarmSettings => 'Exact Alarm Settings';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get addMedicationSchedule => 'Add medication schedule';

  @override
  String get medicationName => 'Medication name';

  @override
  String get dosageHint => 'Dosage (e.g. 2mg)';

  @override
  String get requiredField => 'Required';

  @override
  String timeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get pickTime => 'Pick time';

  @override
  String get saveSchedule => 'Save schedule';

  @override
  String get activeSchedules => 'Active schedules';

  @override
  String get noMedicationsYet => 'No medications yet.';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get exportUnsupported => 'CSV export is not supported on web yet';

  @override
  String csvExportedAt(Object path) {
    return 'CSV exported to: $path';
  }

  @override
  String csvImportDone(int count) {
    return 'Imported $count schedules';
  }

  @override
  String get csvImportInvalid => 'Invalid CSV file';

  @override
  String get csvImportCancelled => 'Import cancelled';

  @override
  String get landingTitle => 'Stay on track with your medication';

  @override
  String get landingSubtitle =>
      'Create reliable reminders, snooze when needed, and never miss a dose.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get splashTitle => 'Mordy';

  @override
  String get takeNow => 'TAKE NOW';

  @override
  String get snoozeTen => 'SNOOZE 10 MIN';

  @override
  String get skip => 'SKIP';

  @override
  String get medicationTime => 'Medication time';

  @override
  String get snoozedMedicationAlarm => 'Snoozed medication alarm';

  @override
  String get alarmScreenTitle => 'Mordy';

  @override
  String get csvHeaderMedicationName => 'medication_name';

  @override
  String get csvHeaderDosage => 'dosage';

  @override
  String get csvHeaderHour => 'hour';

  @override
  String get csvHeaderMinute => 'minute';

  @override
  String get csvHeaderTimezone => 'timezone_name';

  @override
  String get homeTab => 'Home';

  @override
  String get optionsTab => 'Options';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get alarmSound => 'Alarm sound';

  @override
  String get currentSound => 'Current sound';

  @override
  String get chooseSoundFromDevice => 'Choose sound from device';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get deleteAllConfirm => 'Delete all schedules and alarm history?';

  @override
  String get deleteAllDone => 'All data deleted';

  @override
  String get aboutUs => 'About us';

  @override
  String get aboutUsBody =>
      'Mordy helps you manage schedules and reminders offline.';

  @override
  String get help => 'Help';

  @override
  String get helpBody =>
      'Add schedules from Home and manage preferences from Options.';

  @override
  String get support => 'Support';

  @override
  String get supportBody => 'For support, contact the app maintainer.';

  @override
  String get tutorialAddMedication =>
      'Add your medications and schedule times here.';

  @override
  String get tutorialSaveSchedule => 'Tap Save to start scheduling reminders.';

  @override
  String get tutorialOptionsTab =>
      'Open Options for theme, language, sounds, and tools.';
}
