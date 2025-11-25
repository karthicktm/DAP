import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/ai_track.dart';

/// Audio Player Service for playing music tracks
class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  ValueChanged<bool>? _playingStateListener;
  ValueChanged<Duration>? _positionListener;
  ValueChanged<Duration?>? _durationListener;

  AITrack? _currentTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;

  /// Stream subscription for player state
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Stream subscription for position
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// Stream subscription for duration
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  /// Current playing track
  AITrack? get currentTrack => _currentTrack;

  /// Current playing state
  bool get isPlaying => _isPlaying;

  /// Current position
  Duration get currentPosition => _currentPosition;

  /// Current duration
  Duration? get currentDuration => _currentDuration;

  /// Initialize the audio player service
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _playingStateListener?.call(_isPlaying);
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _positionListener?.call(position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration;
      _durationListener?.call(duration);
    });
  }

  /// Play a track
  Future<void> playTrack(AITrack track) async {
    try {
      _currentTrack = track;

      if (kDebugMode) {
        print('🎵 Attempting to play: ${track.title} - ${track.artist}');
        print('📍 Audio URL: ${track.audioUrl}');
        print('🔍 URL length: ${track.audioUrl.length}');
        print('🔍 URL starts with: ${track.audioUrl.substring(0, track.audioUrl.length > 20 ? 20 : track.audioUrl.length)}...');
      }

      // Check if audio URL is valid
      if (track.audioUrl.isEmpty) {
        throw Exception('Track has no audio URL');
      }

      // Set the audio source - handle both assets and URLs
      if (track.audioUrl.startsWith('assets/')) {
        await _audioPlayer.setAsset(track.audioUrl);
      } else {
        await _audioPlayer.setUrl(track.audioUrl);
      }

      // Start playing
      await _audioPlayer.play();

      if (kDebugMode) {
        print('✅ Successfully started playback: ${track.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing track: $e');
        print('📍 Audio URL: ${track.audioUrl}');
        print('🔍 Track processing: ${track.isProcessing}');
        print('🔍 Track completed: ${track.processingCompleted}');
      }
      throw Exception('Failed to play track: $e');
    }
  }

  /// Resume playback
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resuming playback: $e');
      }
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error pausing playback: $e');
      }
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentTrack = null;
      _currentPosition = Duration.zero;
      _currentDuration = null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping playback: $e');
      }
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error seeking: $e');
      }
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting volume: $e');
      }
    }
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting speed: $e');
      }
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      if (_currentTrack == null && _currentPosition == Duration.zero) {
        // No track to play
        return;
      }
      await play();
    }
  }

  /// Check if audio player is playing
  bool get isCurrentlyPlaying {
    return _audioPlayer.playing;
  }

  /// Get current audio player state
  PlayerState get playerState {
    return _audioPlayer.playerState;
  }

  /// Set playing state listener
  void setPlayingStateListener(ValueChanged<bool> listener) {
    _playingStateListener = listener;
  }

  /// Set position listener
  void setPositionListener(ValueChanged<Duration> listener) {
    _positionListener = listener;
  }

  /// Set duration listener
  void setDurationListener(ValueChanged<Duration?> listener) {
    _durationListener = listener;
  }

  /// Get formatted time string
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? twoDigits(duration.inHours) + ':' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_currentDuration == null || _currentDuration!.inMilliseconds == 0) {
      return 0.0;
    }
    return _currentPosition.inMilliseconds / _currentDuration!.inMilliseconds;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _playingStateListener = null;
    _positionListener = null;
    _durationListener = null;
  }
}

/// Singleton instance for global access
class AudioPlayerServiceSingleton {
  static final AudioPlayerServiceSingleton _instance = AudioPlayerServiceSingleton._internal();
  static AudioPlayerService? _audioPlayerService;

  factory AudioPlayerServiceSingleton() {
    return _instance;
  }

  AudioPlayerServiceSingleton._internal();

  AudioPlayerService get audioPlayerService {
    _audioPlayerService ??= AudioPlayerService();
    return _audioPlayerService!;
  }

  Future<void> initialize() async {
    await audioPlayerService.initialize();
  }

  Future<void> dispose() async {
    if (_audioPlayerService != null) {
      await _audioPlayerService!.dispose();
      _audioPlayerService = null;
    }
  }
}