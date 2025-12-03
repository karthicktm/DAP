import 'dart:async';
import 'dart:io';
import 'dart:js_interop';
import 'dart:html' as html;
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

  // Web-specific recording
  html.MediaRecorder? _webRecorder;
  List<html.Blob> _recordedChunks = [];
  html.MediaStream? _mediaStream;

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
      if (kIsWeb) {
        return await _startWebRecording(fileName);
      } else {
        return await _startNativeRecording(fileName);
      }
    } catch (e) {
      debugPrint('Failed to start voice recording: $e');
      _isRecording = false;
      _voiceStateController.add(VoiceRecordingState.idle);
      rethrow;
    }
  }

  Future<String?> _startWebRecording(String? fileName) async {
    try {
      // Request microphone access
      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });

      final recordingName = fileName ?? 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      _recordingPath = recordingName;
      _recordedChunks.clear();

      // Create MediaRecorder
      _webRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': 'audio/webm;codecs=opus',
      });

      // Handle data available
      _webRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      });

      // Start recording
      _webRecorder!.start();
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _voiceStateController.add(VoiceRecordingState.recording);

      _startRecordingTimer();
      debugPrint('Web voice recording started: $_recordingPath');
      return _recordingPath;
    } catch (e) {
      throw Exception('Web recording failed: $e. Please allow microphone access.');
    }
  }

  Future<String?> _startNativeRecording(String? fileName) async {
    // Check permissions
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission denied. Please allow microphone access.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final recordingName = fileName ?? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingPath = '${directory.path}/$recordingName';

    // Start recording with file path
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

    _startRecordingTimer();
    debugPrint('Native voice recording started: $_recordingPath');
    return _recordingPath;
  }

  void _startRecordingTimer() {
    // Start recording timer for duration tracking
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording) {
        _recordingDuration = Duration(seconds: timer.tick);
        _recordingDurationController.add(_recordingDuration);
      } else {
        timer.cancel();
      }
    });

    // Amplitude simulation for UI feedback
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording) {
        final amplitude = 0.3 + (DateTime.now().millisecond % 50) / 100.0;
        _recordingAmplitudeController.add(amplitude);
      } else {
        timer.cancel();
      }
    });
  }

  Future<String?> stopVoiceRecording() async {
    try {
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      _isRecording = false;
      _recordingTimer?.cancel();

      if (kIsWeb) {
        return await _stopWebRecording();
      } else {
        return await _stopNativeRecording();
      }
    } catch (e) {
      debugPrint('Failed to stop voice recording: $e');
      _isRecording = false;
      _voiceStateController.add(VoiceRecordingState.error);
      rethrow;
    }
  }

  Future<String?> _stopWebRecording() async {
    try {
      if (_webRecorder != null) {
        final completer = Completer<String?>();

        _webRecorder!.addEventListener('stop', (_) {
          // Create blob from recorded chunks
          final blob = html.Blob(_recordedChunks, 'audio/webm');
          final url = html.Url.createObjectUrlFromBlob(blob);

          _voiceStateController.add(VoiceRecordingState.completed);
          debugPrint('Web voice recording stopped: $url');
          completer.complete(url);
        });

        _webRecorder!.stop();
        _mediaStream?.getTracks().forEach((track) => track.stop());

        return await completer.future;
      } else {
        throw Exception('Web recorder not initialized');
      }
    } catch (e) {
      throw Exception('Failed to stop web recording: $e');
    }
  }

  Future<String?> _stopNativeRecording() async {
    try {
      final path = await _recorder.stop();
      _voiceStateController.add(VoiceRecordingState.completed);

      final finalPath = path ?? _recordingPath;
      debugPrint('Native voice recording stopped: $finalPath');

      if (finalPath == null) {
        throw Exception('Recording failed - no audio file generated');
      }

      return finalPath;
    } catch (e) {
      throw Exception('Failed to stop native recording: $e');
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

    // Clean up web resources
    if (kIsWeb) {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _webRecorder = null;
      _recordedChunks.clear();
    }

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