import 'package:audioplayers/audioplayers.dart';

import '../models/app_settings.dart';

class AlarmSoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playLoop(AppAlarmSound sound) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    if (sound.isAsset) {
      await _player.play(AssetSource(sound.path));
      return;
    }
    await _player.play(DeviceFileSource(sound.path));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

