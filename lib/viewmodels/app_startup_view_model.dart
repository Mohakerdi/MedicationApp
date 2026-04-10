import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupStage { splash, landing, home }

class AppStartupViewModel extends ChangeNotifier {
  static const _seenLandingKey = 'seen_landing_once';

  StartupStage _stage = StartupStage.splash;
  StartupStage get stage => _stage;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final results = await Future.wait<Object>([
      SharedPreferences.getInstance(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    final prefs = results.first as SharedPreferences;
    final seenLanding = prefs.getBool(_seenLandingKey) ?? false;
    _stage = seenLanding ? StartupStage.home : StartupStage.landing;
    notifyListeners();
  }

  Future<void> completeLanding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenLandingKey, true);
    _stage = StartupStage.home;
    notifyListeners();
  }
}
