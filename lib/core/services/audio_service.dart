import 'package:audioplayers/audioplayers.dart';

/// Service for playing audio feedback and music
class AudioService {
  final _audioPlayer = AudioPlayer();
  final _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  /// Enable or disable sound effects
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Enable or disable background music
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }

  /// Play correct answer sound
  Future<void> playCorrectSound() async {
    if (!_soundEnabled) return;
    try {
      await _playAssetWithFallback(
        player: _audioPlayer,
        primary: 'sounds/correct.mp3',
        fallback: 'sounds/correct.wav',
      );
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Play wrong answer sound
  Future<void> playWrongSound() async {
    if (!_soundEnabled) return;
    try {
      await _playAssetWithFallback(
        player: _audioPlayer,
        primary: 'sounds/wrong.mp3',
        fallback: 'sounds/wrong.wav',
      );
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Play celebration sound
  Future<void> playCelebrationSound() async {
    if (!_soundEnabled) return;
    try {
      await _playAssetWithFallback(
        player: _audioPlayer,
        primary: 'sounds/celebration.mp3',
        fallback: 'sounds/celebration.wav',
      );
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Play button click sound
  Future<void> playClickSound() async {
    if (!_soundEnabled) return;
    try {
      await _playAssetWithFallback(
        player: _audioPlayer,
        primary: 'sounds/click.mp3',
        fallback: 'sounds/click.wav',
      );
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Play background music
  Future<void> playMusic() async {
    if (!_musicEnabled) return;
    try {
      await _playAssetWithFallback(
        player: _musicPlayer,
        primary: 'sounds/background_music.mp3',
        fallback: 'sounds/background_music.wav',
        volume: 0.3,
      );
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _playAssetWithFallback({
    required AudioPlayer player,
    required String primary,
    required String fallback,
    double? volume,
  }) async {
    try {
      await player.play(AssetSource(primary), volume: volume);
    } catch (_) {
      await player.play(AssetSource(fallback), volume: volume);
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  /// Dispose audio players
  void dispose() {
    _audioPlayer.dispose();
    _musicPlayer.dispose();
  }
}
