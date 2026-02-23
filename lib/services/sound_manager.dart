import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal() {
    _init();
  }

  void _init() {
    // Set global context for Android to ensure sound plays even in silent mode if needed,
    // and to handle modern Android (14/15/16) audio policies.
    AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransient,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));
  }

  final AudioPlayer _player = AudioPlayer();

  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> _playSound(String fileName) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      print('SoundManager error: Could not play $fileName. $e');
    }
  }

  void playMove() => _playSound('move.mp3');
  void playCapture() => _playSound('capture.mp3');
  void playCheck() => _playSound('check.mp3');
  void playWin() => _playSound('move.mp3'); // Still fallback
  void playLose() => _playSound('move.mp3'); // Still fallback
}
