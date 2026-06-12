import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/monster_catalog.dart';

/// Provider to manage background music playback.
class MusicProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _monsterId = MonsterCatalog.defaultId;
  List<String> _tracks = [];
  int _currentTrackIndex = 0;
  StreamSubscription<void>? _playerStateSubscription;
  final math.Random _random = math.Random();

  bool get isPlaying => _isPlaying;

  MusicProvider() {
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setVolume(0.6);

    try {
      _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting audio context: $e');
    }

    _playerStateSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _playNextTrack();
    });
  }

  /// Toggle music for the selected child's monster.
  Future<void> playMusic({required String monsterId}) async {
    if (_isPlaying) {
      await stopMusic();
      return;
    }

    _monsterId = MonsterCatalog.normalizeMonsterId(monsterId);
    _tracks = MonsterCatalog.musicTracks(_monsterId);
    if (_tracks.isEmpty) {
      debugPrint('No music tracks for monster: $_monsterId');
      return;
    }

    try {
      _isPlaying = true;
      notifyListeners();
      final track = _tracks[_random.nextInt(_tracks.length)];
      await _playTrackPath(track);
    } catch (e) {
      debugPrint('Error playing music: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> _playTrackPath(String trackPath) async {
    debugPrint('Playing track: $trackPath');
    await _audioPlayer.stop();
    await _audioPlayer.setVolume(0.5);
    await _audioPlayer.play(AssetSource(trackPath));
    _currentTrackIndex = _tracks.indexOf(trackPath);
    notifyListeners();
  }

  Future<void> _playNextTrack() async {
    if (!_isPlaying || _tracks.isEmpty) return;

    int nextIndex;
    if (_tracks.length > 1) {
      do {
        nextIndex = _random.nextInt(_tracks.length);
      } while (nextIndex == _currentTrackIndex);
    } else {
      nextIndex = 0;
    }

    try {
      await _playTrackPath(_tracks[nextIndex]);
    } catch (e) {
      debugPrint('Error playing next track: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
