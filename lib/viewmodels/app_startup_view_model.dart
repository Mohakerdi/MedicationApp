import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupStage { splash, landing, home }

class AppStartupViewModel extends ChangeNotifier {
  static const _seenLandingKey = 'seen_landing_once';
  static const _minimumSplashDuration = Duration(seconds: 2);
  static const _prefsInitTimeout = Duration(seconds: 5);

  StartupStage _stage = StartupStage.splash;
  StartupStage get stage => _stage;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final results = await Future.wait<Object>([
        SharedPreferences.getInstance().timeout(_prefsInitTimeout),
        Future<Object>.delayed(_minimumSplashDuration),
      ]);
      final prefs = results.first as SharedPreferences;
      final seenLanding = prefs.getBool(_seenLandingKey) ?? false;
      _stage = seenLanding ? StartupStage.home : StartupStage.landing;
    } catch (error) {
      debugPrint('Startup initialization failed: $error');
      _stage = StartupStage.landing;
    }
    notifyListeners();
  }

  Future<void> completeLanding() async {
    _stage = StartupStage.home;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenLandingKey, true);
    } catch (error) {
      debugPrint('Persisting landing completion failed: $error');
    }
  }
}
