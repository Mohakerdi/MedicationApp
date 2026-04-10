import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class AppSettingsService {
  static const themeModeKey = 'app_theme_mode';
  static const localeCodeKey = 'app_locale_code';
  static const selectedSoundIdKey = 'app_selected_sound_id';
  static const seenHomeTutorialKey = 'seen_home_tutorial';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeRaw = prefs.getString(themeModeKey);
    final localeCode = prefs.getString(localeCodeKey);
    final selectedSoundId =
        prefs.getString(selectedSoundIdKey) ?? defaultAlarmSounds.first.id;
    final seenHomeTutorial = prefs.getBool(seenHomeTutorialKey) ?? false;

    return AppSettings(
      themeMode: _themeFromRaw(themeRaw),
      localeCode: localeCode,
      selectedSoundId: selectedSoundId,
      seenHomeTutorial: seenHomeTutorial,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  Future<void> saveLocaleCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(localeCodeKey);
      return;
    }
    await prefs.setString(localeCodeKey, code);
  }

  Future<void> saveSelectedSoundId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedSoundIdKey, id);
  }

  Future<void> saveSeenHomeTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenHomeTutorialKey, value);
  }

  ThemeMode _themeFromRaw(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}

const List<AppAlarmSound> defaultAlarmSounds = [
  AppAlarmSound(
    id: 'asset_chime',
    label: 'Gentle Chime',
    type: AppAlarmSoundType.asset,
    path: 'sounds/chime.wav',
  ),
  AppAlarmSound(
    id: 'asset_beacon',
    label: 'Beacon',
    type: AppAlarmSoundType.asset,
    path: 'sounds/beacon.wav',
  ),
  AppAlarmSound(
    id: 'asset_alert',
    label: 'Alert Tone',
    type: AppAlarmSoundType.asset,
    path: 'sounds/alert.wav',
  ),
];

