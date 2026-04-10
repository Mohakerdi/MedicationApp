import 'package:flutter/material.dart';
import 'package:medecation_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_database.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'services/alarm_scheduler.dart';
import 'services/app_settings_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/app_settings_view_model.dart';
import 'viewmodels/app_startup_view_model.dart';

class MedicationApp extends StatefulWidget {
  const MedicationApp({
    super.key,
    required this.database,
    required this.notifications,
    required this.scheduler,
    this.initialAlarmId,
  });

  final AppDatabase database;
  final NotificationService notifications;
  final AlarmScheduler scheduler;
  final int? initialAlarmId;

  @override
  State<MedicationApp> createState() => _MedicationAppState();
}

class _MedicationAppState extends State<MedicationApp> {
  final AppStartupViewModel _startupViewModel = AppStartupViewModel();
  final AppSettingsViewModel _settingsViewModel = AppSettingsViewModel(
    settingsService: AppSettingsService(),
  );

  @override
  void initState() {
    super.initState();
    _startupViewModel.initialize();
    _settingsViewModel.initialize();
  }

  @override
  void dispose() {
    _startupViewModel.dispose();
    _settingsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_startupViewModel, _settingsViewModel]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _settingsViewModel.themeMode,
        locale: _settingsViewModel.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: switch (_startupViewModel.stage) {
          StartupStage.splash => const SplashScreen(),
          StartupStage.landing => LandingScreen(
            onGetStarted: _startupViewModel.completeLanding,
          ),
          StartupStage.home => HomeScreen(
            database: widget.database,
            scheduler: widget.scheduler,
            notifications: widget.notifications,
            initialAlarmId: widget.initialAlarmId,
            settingsViewModel: _settingsViewModel,
          ),
        },
      ),
    );
  }
}
