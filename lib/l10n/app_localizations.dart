import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mordy'**
  String get appTitle;

  /// No description provided for @exactAlarmsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms enabled'**
  String get exactAlarmsEnabled;

  /// No description provided for @exactAlarmsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms not enabled'**
  String get exactAlarmsDisabled;

  /// No description provided for @grantAlarmPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Alarm Permissions'**
  String get grantAlarmPermissions;

  /// No description provided for @exactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Exact Alarm Settings'**
  String get exactAlarmSettings;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @addMedicationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add medication schedule'**
  String get addMedicationSchedule;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medicationName;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'Dosage (e.g. 2mg)'**
  String get dosageHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeLabel(Object time);

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pickTime;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get saveSchedule;

  /// No description provided for @activeSchedules.
  ///
  /// In en, this message translates to:
  /// **'Active schedules'**
  String get activeSchedules;

  /// No description provided for @noMedicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No medications yet.'**
  String get noMedicationsYet;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @exportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'CSV export is not supported on web yet'**
  String get exportUnsupported;

  /// No description provided for @csvExportedAt.
  ///
  /// In en, this message translates to:
  /// **'CSV exported to: {path}'**
  String csvExportedAt(Object path);

  /// No description provided for @csvImportDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} schedules'**
  String csvImportDone(int count);

  /// No description provided for @csvImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid CSV file'**
  String get csvImportInvalid;

  /// No description provided for @csvImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled'**
  String get csvImportCancelled;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track with your medication'**
  String get landingTitle;

  /// No description provided for @landingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create reliable reminders, snooze when needed, and never miss a dose.'**
  String get landingSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Mordy'**
  String get splashTitle;

  /// No description provided for @takeNow.
  ///
  /// In en, this message translates to:
  /// **'TAKE NOW'**
  String get takeNow;

  /// No description provided for @snoozeTen.
  ///
  /// In en, this message translates to:
  /// **'SNOOZE 10 MIN'**
  String get snoozeTen;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @medicationTime.
  ///
  /// In en, this message translates to:
  /// **'Medication time'**
  String get medicationTime;

  /// No description provided for @snoozedMedicationAlarm.
  ///
  /// In en, this message translates to:
  /// **'Snoozed medication alarm'**
  String get snoozedMedicationAlarm;

  /// No description provided for @alarmScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Mordy'**
  String get alarmScreenTitle;

  /// No description provided for @csvHeaderMedicationName.
  ///
  /// In en, this message translates to:
  /// **'medication_name'**
  String get csvHeaderMedicationName;

  /// No description provided for @csvHeaderDosage.
  ///
  /// In en, this message translates to:
  /// **'dosage'**
  String get csvHeaderDosage;

  /// No description provided for @csvHeaderHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get csvHeaderHour;

  /// No description provided for @csvHeaderMinute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get csvHeaderMinute;

  /// No description provided for @csvHeaderTimezone.
  ///
  /// In en, this message translates to:
  /// **'timezone_name'**
  String get csvHeaderTimezone;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @optionsTab.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTab;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get alarmSound;

  /// No description provided for @currentSound.
  ///
  /// In en, this message translates to:
  /// **'Current sound'**
  String get currentSound;

  /// No description provided for @chooseSoundFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose sound from device'**
  String get chooseSoundFromDevice;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all schedules and alarm history?'**
  String get deleteAllConfirm;

  /// No description provided for @deleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get deleteAllDone;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// No description provided for @aboutUsBody.
  ///
  /// In en, this message translates to:
  /// **'Mordy helps you manage schedules and reminders offline.'**
  String get aboutUsBody;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'Add schedules from Home and manage preferences from Options.'**
  String get helpBody;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'For support, contact the app maintainer.'**
  String get supportBody;

  /// No description provided for @tutorialAddMedication.
  ///
  /// In en, this message translates to:
  /// **'Add your medications and schedule times here.'**
  String get tutorialAddMedication;

  /// No description provided for @tutorialSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Tap Save to start scheduling reminders.'**
  String get tutorialSaveSchedule;

  /// No description provided for @tutorialOptionsTab.
  ///
  /// In en, this message translates to:
  /// **'Open Options for theme, language, sounds, and tools.'**
  String get tutorialOptionsTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
