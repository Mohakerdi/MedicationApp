import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_database.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'services/alarm_scheduler.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _startupViewModel.initialize();
  }

  @override
  void dispose() {
    _startupViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _startupViewModel,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light(),
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
          ),
        },
      ),
    );
  }
}
