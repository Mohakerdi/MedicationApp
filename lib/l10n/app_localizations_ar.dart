// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Mordy';

  @override
  String get exactAlarmsEnabled => 'تم تفعيل المنبهات الدقيقة';

  @override
  String get exactAlarmsDisabled => 'المنبهات الدقيقة غير مفعلة';

  @override
  String get grantAlarmPermissions => 'منح صلاحيات المنبه';

  @override
  String get exactAlarmSettings => 'إعدادات المنبهات الدقيقة';

  @override
  String get batteryOptimization => 'تحسين البطارية';

  @override
  String get addMedicationSchedule => 'إضافة جدول دواء';

  @override
  String get medicationName => 'اسم الدواء';

  @override
  String get dosageHint => 'الجرعة (مثال: 2mg)';

  @override
  String get requiredField => 'مطلوب';

  @override
  String timeLabel(Object time) {
    return 'الوقت: $time';
  }

  @override
  String get pickTime => 'اختيار الوقت';

  @override
  String get saveSchedule => 'حفظ الجدول';

  @override
  String get activeSchedules => 'الجداول النشطة';

  @override
  String get noMedicationsYet => 'لا توجد أدوية بعد.';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get importCsv => 'استيراد CSV';

  @override
  String get exportUnsupported => 'تصدير CSV غير مدعوم على الويب حالياً';

  @override
  String csvExportedAt(Object path) {
    return 'تم تصدير CSV إلى: $path';
  }

  @override
  String csvImportDone(int count) {
    return 'تم استيراد $count جدول';
  }

  @override
  String get csvImportInvalid => 'ملف CSV غير صالح';

  @override
  String get csvImportCancelled => 'تم إلغاء الاستيراد';

  @override
  String get landingTitle => 'التزم بأدويتك بسهولة';

  @override
  String get landingSubtitle =>
      'أنشئ تذكيرات موثوقة، وأجّل عند الحاجة، ولا تفوّت أي جرعة.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get splashTitle => 'Mordy';

  @override
  String get takeNow => 'تناول الآن';

  @override
  String get snoozeTen => 'غفوة 10 دقائق';

  @override
  String get skip => 'تخطي';

  @override
  String get medicationTime => 'موعد الدواء';

  @override
  String get snoozedMedicationAlarm => 'منبه دواء مؤجل';

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
  String get homeTab => 'الرئيسية';

  @override
  String get optionsTab => 'الخيارات';

  @override
  String get themeMode => 'وضع المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'افتراضي النظام';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get alarmSound => 'نغمة المنبه';

  @override
  String get currentSound => 'النغمة الحالية';

  @override
  String get chooseSoundFromDevice => 'اختيار نغمة من الجهاز';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get deleteAllConfirm => 'حذف كل الجداول وسجل التنبيهات؟';

  @override
  String get deleteAllDone => 'تم حذف جميع البيانات';

  @override
  String get aboutUs => 'من نحن';

  @override
  String get aboutUsBody =>
      'Mordy يساعدك على إدارة الجداول والتنبيهات دون اتصال.';

  @override
  String get help => 'مساعدة';

  @override
  String get helpBody => 'أضف الجداول من الرئيسية وأدر التفضيلات من الخيارات.';

  @override
  String get support => 'الدعم';

  @override
  String get supportBody => 'للدعم، تواصل مع مسؤول التطبيق.';

  @override
  String get tutorialAddMedication => 'أضف أدويتك وحدد الأوقات من هنا.';

  @override
  String get tutorialSaveSchedule => 'اضغط حفظ لبدء جدولة التذكيرات.';

  @override
  String get tutorialOptionsTab =>
      'افتح الخيارات للمظهر واللغة والنغمات والأدوات.';
}
