import 'dart:async';
import 'package:flutter/foundation.dart';

// Mock audio service for development
class AudioService {
  bool _isRecording = false;
  bool _isPlaying = false;

  final StreamController<double> _recordingAmplitudeController =
      StreamController.broadcast();
  final StreamController<bool> _playbackStateController =
      StreamController.broadcast();

  AudioService();

  Stream<double> get recordingAmplitudeStream =>
      _recordingAmplitudeController.stream;
  Stream<bool> get playbackStateStream =>
      _playbackStateController.stream;

  Future<String?> startRecording({String? fileName}) async {
    try {
      _isRecording = true;

      // Mock amplitude data for visualization
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isRecording) {
          final amplitude = (DateTime.now().millisecond % 100) / 100.0;
          _recordingAmplitudeController.add(amplitude);
        } else {
          timer.cancel();
        }
      });

      debugPrint('Recording started: mock_recording.wav');
      return 'mock_recording.wav';
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      _isRecording = false;
      debugPrint('Recording stopped: mock_recording.wav');
      return 'mock_recording.wav';
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      rethrow;
    }
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

  Future<void> dispose() async {
    await _recordingAmplitudeController.close();
    await _playbackStateController.close();
  }
}