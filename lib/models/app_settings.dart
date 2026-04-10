import 'package:flutter/material.dart';

enum AppAlarmSoundType { asset, device }

class AppAlarmSound {
  const AppAlarmSound({
    required this.id,
    required this.label,
    required this.type,
    required this.path,
  });

  final String id;
  final String label;
  final AppAlarmSoundType type;
  final String path;

  bool get isAsset => type == AppAlarmSoundType.asset;
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    this.localeCode,
    required this.selectedSoundId,
    required this.seenHomeTutorial,
  });

  final ThemeMode themeMode;
  final String? localeCode;
  final String selectedSoundId;
  final bool seenHomeTutorial;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool clearLocaleCode = false,
    String? selectedSoundId,
    bool? seenHomeTutorial,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
      selectedSoundId: selectedSoundId ?? this.selectedSoundId,
      seenHomeTutorial: seenHomeTutorial ?? this.seenHomeTutorial,
    );
  }
}

