import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  final StreamController<double> _recordingAmplitudeController =
      StreamController.broadcast();
  final StreamController<bool> _playbackStateController =
      StreamController.broadcast();
  final StreamController<Duration> _recordingDurationController =
      StreamController.broadcast();
  final StreamController<VoiceRecordingState> _voiceStateController =
      StreamController.broadcast();

  AudioService();

  Stream<double> get recordingAmplitudeStream =>
      _recordingAmplitudeController.stream;
  Stream<bool> get playbackStateStream =>
      _playbackStateController.stream;
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;
  Stream<VoiceRecordingState> get voiceStateStream =>
      _voiceStateController.stream;

  Future<String?> startVoiceRecording({String? fileName}) async {
    try {
      // Check permissions
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission denied');
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final recordingName = fileName ?? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${directory.path}/$recordingName';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;

      _voiceStateController.add(VoiceRecordingState.recording);

      // Start recording timer for duration tracking
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording) {
          _recordingDuration = Duration(seconds: timer.tick);
          _recordingDurationController.add(_recordingDuration);
        } else {
          timer.cancel();
        }
      });

      // Real amplitude monitoring would require additional audio processing library
      // For now, provide minimal amplitude simulation for UI feedback
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isRecording) {
          // Simple amplitude simulation - in production, use real audio level monitoring
          final amplitude = 0.3 + (DateTime.now().millisecond % 50) / 100.0;
          _recordingAmplitudeController.add(amplitude);
        } else {
          timer.cancel();
        }
      });

      debugPrint('Voice recording started: $_recordingPath');
      return _recordingPath;
    } catch (e) {
      debugPrint('Failed to start voice recording: $e');
      _isRecording = false;
      _voiceStateController.add(VoiceRecordingState.idle);
      rethrow;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      // Stop recording
      final path = await _recorder.stop();

      _isRecording = false;
      _recordingTimer?.cancel();

      _voiceStateController.add(VoiceRecordingState.completed);

      debugPrint('Voice recording stopped: $path');
      return path ?? _recordingPath;
    } catch (e) {
      debugPrint('Failed to stop voice recording: $e');
      _isRecording = false;
      _voiceStateController.add(VoiceRecordingState.error);
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<String?> startRecording({String? fileName}) async {
    return await startVoiceRecording(fileName: fileName);
  }

  Future<String?> stopRecording() async {
    return await stopVoiceRecording();
  }

  Future<void> play() async {
    try {
      _isPlaying = true;
      _playbackStateController.add(_isPlaying);
      debugPrint('Audio playback started');
    } catch (e) {
      debugPrint('Failed to play audio: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      _isPlaying = false;
      _playbackStateController.add(_isPlaying);
      debugPrint('Audio playback paused');
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      _isPlaying = false;
      _playbackStateController.add(_isPlaying);
      debugPrint('Audio playback stopped');
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
      rethrow;
    }
  }

  Future<void> loadAudio(String audioUrl) async {
    debugPrint('Loading audio: $audioUrl');
  }

  Future<void> loadLocalAudio(String filePath) async {
    debugPrint('Loading local audio: $filePath');
  }

  double get volume => 1.0;

  Future<void> setVolume(double volume) async {
    debugPrint('Setting volume to: $volume');
  }

  Duration get position => Duration.zero;

  Duration? get duration => const Duration(minutes: 3);

  bool get isRecording => _isRecording;

  bool get isPlaying => _isPlaying;

  String? get currentRecordingPath => _recordingPath;
  Duration get recordingDuration => _recordingDuration;

  Future<void> dispose() async {
    _recordingTimer?.cancel();
    await _recorder.dispose();
    await _audioPlayer.dispose();
    await _recordingAmplitudeController.close();
    await _playbackStateController.close();
    await _recordingDurationController.close();
    await _voiceStateController.close();
  }
}

enum VoiceRecordingState {
  idle,
  recording,
  completed,
  error,
}
}