import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_service.dart';

class AppSettingsViewModel extends ChangeNotifier {
  AppSettingsViewModel({required this.settingsService});

  final AppSettingsService settingsService;

  AppSettings _settings = const AppSettings(
    themeMode: ThemeMode.system,
    localeCode: null,
    selectedSoundId: 'asset_chime',
    seenHomeTutorial: false,
  );

  bool _initialized = false;

  AppSettings get settings => _settings;
  bool get initialized => _initialized;
  ThemeMode get themeMode => _settings.themeMode;
  Locale? get locale =>
      _settings.localeCode == null ? null : Locale(_settings.localeCode!);
  bool get shouldShowHomeTutorial => !_settings.seenHomeTutorial;
  List<AppAlarmSound> get soundOptions => defaultAlarmSounds;

  AppAlarmSound get selectedSound {
    final fromDefaults = defaultAlarmSounds.where(
      (item) => item.id == _settings.selectedSoundId,
    );
    if (fromDefaults.isNotEmpty) {
      return fromDefaults.first;
    }
    return AppAlarmSound(
      id: _settings.selectedSoundId,
      label: 'Device sound',
      type: AppAlarmSoundType.device,
      path: _settings.selectedSoundId.replaceFirst('device:', ''),
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _settings = await settingsService.load();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await settingsService.saveThemeMode(mode);
  }

  Future<void> setLocaleCode(String? code) async {
    _settings = _settings.copyWith(
      localeCode: code,
      clearLocaleCode: code == null,
    );
    notifyListeners();
    await settingsService.saveLocaleCode(code);
  }

  Future<void> setSelectedAssetSound(String soundId) async {
    _settings = _settings.copyWith(selectedSoundId: soundId);
    notifyListeners();
    await settingsService.saveSelectedSoundId(soundId);
  }

  Future<void> setSelectedDeviceSoundPath(String path) async {
    final id = 'device:$path';
    _settings = _settings.copyWith(selectedSoundId: id);
    notifyListeners();
    await settingsService.saveSelectedSoundId(id);
  }

  Future<void> markHomeTutorialSeen() async {
    if (_settings.seenHomeTutorial) {
      return;
    }
    _settings = _settings.copyWith(seenHomeTutorial: true);
    notifyListeners();
    await settingsService.saveSeenHomeTutorial(true);
  }
}

