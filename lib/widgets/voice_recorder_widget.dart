import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/ai_voice_service.dart';
import '../utils/logger.dart';

/// Voice recorder widget with AI processing for song creation
class VoiceRecorderWidget extends ConsumerStatefulWidget {
  final Function(CompleteSongResult)? onSongGenerated;
  final VoidCallback? onError;

  const VoiceRecorderWidget({
    super.key,
    this.onSongGenerated,
    this.onError,
  });

  @override
  ConsumerState<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends ConsumerState<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final AIVoiceService _aiVoiceService = AIVoiceService();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  VoiceRecordingState _currentState = VoiceRecordingState.idle;
  Duration _recordingDuration = Duration.zero;
  bool _isProcessing = false;
  String? _statusMessage;
  CompleteSongResult? _songResult;

  // WAV conversion states
  WavConversionResult? _wavConversionResult;
  WavConversionStatus? _wavStatus;
  bool _isPollingWavStatus = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupStreams();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  void _setupStreams() {
    _audioService.voiceStateStream.listen((state) {
      setState(() {
        _currentState = state;
        if (state == VoiceRecordingState.recording) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _waveController.stop();
        }
      });
    });

    _audioService.recordingDurationStream.listen((duration) {
      setState(() {
        _recordingDuration = duration;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStateColor().withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _getStateColor().withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildRecordingVisualizer(),
          const SizedBox(height: 32),
          _buildControls(),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            _buildStatusMessage(),
          ],
          if (_songResult != null) ...[
            const SizedBox(height: 24),
            _buildSongResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          _getStateIcon(),
          color: _getStateColor(),
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          _getStateTitle(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getStateDescription(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordingVisualizer() {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer wave animation
          if (_currentState == VoiceRecordingState.recording)
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStateColor().withOpacity(0.3 * _waveAnimation.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

          // Main recording button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentState == VoiceRecordingState.recording
                    ? _pulseAnimation.value
                    : 1.0,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStateColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateColor().withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStateIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),

          // Recording duration
          if (_currentState == VoiceRecordingState.recording)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_currentState == VoiceRecordingState.idle) ...[
          _buildControlButton(
            icon: Icons.mic,
            label: 'Start Recording',
            onPressed: _isProcessing ? null : _startRecording,
            color: const Color(0xFF8B5CF6),
          ),
        ],

        if (_currentState == VoiceRecordingState.recording) ...[
          _buildControlButton(
            icon: Icons.stop,
            label: 'Stop Recording',
            onPressed: _stopRecording,
            color: Colors.red,
          ),
          const SizedBox(width: 16),
          _buildControlButton(
            icon: Icons.pause,
            label: 'Pause',
            onPressed: _pauseRecording,
            color: Colors.orange,
          ),
        ],

        if (_currentState == VoiceRecordingState.completed && !_isProcessing) ...[
          // Show status or appropriate button based on WAV conversion state
          if (_wavStatus?.isCompleted == true) ...[
            _buildControlButton(
              icon: Icons.auto_awesome,
              label: 'Generate Music',
              onPressed: _generateMusicWithWav,
              color: const Color(0xFF14B8A6),
            ),
            const SizedBox(width: 16),
          ] else if (_wavConversionResult != null && _wavStatus?.isProcessing == true) ...[
            _buildControlButton(
              icon: Icons.hourglass_empty,
              label: 'Converting to WAV...',
              onPressed: null, // Disabled during processing
              color: Colors.grey,
            ),
          ] else if (_wavConversionResult == null) ...[
            _buildControlButton(
              icon: Icons.file_upload,
              label: 'Convert to WAV',
              onPressed: _uploadAndConvertToWav,
              color: const Color(0xFF14B8A6),
            ),
            const SizedBox(width: 16),
          ],
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Record Again',
            onPressed: _resetRecording,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (_isProcessing) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              _statusMessage!,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongResult() {
    if (_songResult == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Song Generated Successfully!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultItem('Mood', _songResult!.analysis.mood),
          _buildResultItem('Genre', _songResult!.analysis.genre),
          _buildResultItem('Confidence', '${(_songResult!.analysis.confidence * 100).toInt()}%'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => widget.onSongGenerated?.call(_songResult!),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Generated Song'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_currentState) {
      case VoiceRecordingState.idle:
        return const Color(0xFF8B5CF6);
      case VoiceRecordingState.recording:
        return Colors.red;
      case VoiceRecordingState.completed:
        return Colors.green;
      case VoiceRecordingState.error:
        return Colors.orange;
    }
  }

  IconData _getStateIcon() {
    switch (_currentState) {
      case VoiceRecordingState.idle:
        return Icons.mic;
      case VoiceRecordingState.recording:
        return Icons.mic;
      case VoiceRecordingState.completed:
        return Icons.check;
      case VoiceRecordingState.error:
        return Icons.error;
    }
  }

  String _getStateTitle() {
    switch (_currentState) {
      case VoiceRecordingState.idle:
        return 'Voice to Song AI';
      case VoiceRecordingState.recording:
        return 'Recording...';
      case VoiceRecordingState.completed:
        return 'Recording Complete';
      case VoiceRecordingState.error:
        return 'Recording Error';
    }
  }

  String _getStateDescription() {
    switch (_currentState) {
      case VoiceRecordingState.idle:
        return 'Record your voice and AI will generate background music, complete lyrics, and create a full song';
      case VoiceRecordingState.recording:
        return 'Sing or speak your lyrics. AI will analyze mood and style automatically';
      case VoiceRecordingState.completed:
        return 'Great! Your voice has been recorded. Generate your AI song now';
      case VoiceRecordingState.error:
        return 'Something went wrong with the recording. Please try again';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _statusMessage = 'Starting voice recording...';
      });

      await _audioService.startVoiceRecording();

      setState(() {
        _statusMessage = null;
      });
    } catch (e) {
      String errorMessage = 'Failed to start recording: $e';

      // Provide helpful error messages for common issues
      if (e.toString().contains('permission')) {
        errorMessage = 'Microphone permission required. Please allow access and try again.';
      } else if (e.toString().contains('not supported')) {
        errorMessage = 'Audio recording not supported in this browser. Try Chrome or Firefox.';
      }

      setState(() {
        _statusMessage = errorMessage;
        _currentState = VoiceRecordingState.error;
      });
      widget.onError?.call();
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _statusMessage = 'Stopping recording...';
      });

      await _audioService.stopVoiceRecording();

      setState(() {
        _statusMessage = null;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to stop recording: $e';
        _currentState = VoiceRecordingState.error;
      });
      widget.onError?.call();
    }
  }

  Future<void> _pauseRecording() async {
    // Implementation would depend on audio service capabilities
    Logger.log('Pause recording requested');
  }

  // New method to upload and convert to WAV
  Future<void> _uploadAndConvertToWav() async {
    try {
      final recordingPath = _audioService.currentRecordingPath;
      if (recordingPath == null) {
        throw Exception('No recording found');
      }

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Uploading voice file and converting to WAV...';
      });

      // Upload file and start WAV conversion
      final wavResult = await _aiVoiceService.uploadVoiceFileForWavConversion(recordingPath);

      setState(() {
        _wavConversionResult = wavResult;
        _statusMessage = 'Converting to WAV format...';
        _isProcessing = false;
      });

      // Start polling for WAV conversion status
      _startWavStatusPolling();

      Logger.log('WAV conversion started with taskId: ${wavResult.wavTaskId}');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'WAV conversion failed: $e';
        _currentState = VoiceRecordingState.error;
      });
      Logger.log('WAV conversion error: $e');
      widget.onError?.call();
    }
  }

  // Poll WAV conversion status
  void _startWavStatusPolling() {
    if (_wavConversionResult == null || _isPollingWavStatus) return;

    _isPollingWavStatus = true;
    _pollWavStatus();
  }

  Future<void> _pollWavStatus() async {
    if (!_isPollingWavStatus || _wavConversionResult == null) return;

    try {
      final status = await _aiVoiceService.getWavConversionStatus(_wavConversionResult!.wavTaskId);

      setState(() {
        _wavStatus = status;

        if (status.isCompleted) {
          _statusMessage = 'WAV conversion completed! Ready to generate music.';
          _isPollingWavStatus = false;
        } else if (status.hasError) {
          _statusMessage = 'WAV conversion failed: ${status.message}';
          _currentState = VoiceRecordingState.error;
          _isPollingWavStatus = false;
        } else {
          _statusMessage = 'Converting to WAV... ${status.message}';
        }
      });

      if (status.isProcessing) {
        // Continue polling after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        _pollWavStatus();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking WAV status: $e';
        _isPollingWavStatus = false;
      });
      Logger.log('WAV status polling error: $e');
    }
  }

  // Generate music using converted WAV file
  Future<void> _generateMusicWithWav() async {
    try {
      if (_wavStatus?.wavUrl == null || _wavStatus!.wavUrl.isEmpty) {
        throw Exception('WAV file not available');
      }

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Generating music with your voice...';
      });

      // Analyze voice for music generation parameters
      final recordingPath = _audioService.currentRecordingPath;
      if (recordingPath == null) {
        throw Exception('No recording found');
      }

      final voiceResult = await _aiVoiceService.voiceToLyrics(recordingPath);

      // Create analysis for music generation
      final analysis = VoiceAnalysis(
        mood: voiceResult.analyzedMood,
        genre: voiceResult.detectedGenre,
        tempo: voiceResult.suggestedTempo,
        confidence: voiceResult.confidence,
      );

      // Complete the lyrics
      final completedLyrics = await _aiVoiceService.completeLyrics(
        originalLyrics: voiceResult.originalText,
        mood: analysis.mood,
        genre: analysis.genre,
      );

      // Generate music using the WAV file
      final taskId = await _aiVoiceService.generateBackgroundMusic(
        analysis: analysis,
        completedLyrics: completedLyrics,
        uploadedFileId: _wavStatus!.wavUrl, // Use WAV URL instead of original file
      );

      setState(() {
        _statusMessage = 'Music generation started! This may take a few minutes...';
        _isProcessing = false;
      });

      // Create result object (will be updated when music is ready)
      final result = CompleteSongResult(
        originalVoiceRecording: recordingPath,
        transcribedLyrics: voiceResult.originalText,
        completedLyrics: completedLyrics,
        backgroundMusicUrl: '', // Will be updated via webhook
        analysis: analysis,
        finalMixedSongUrl: taskId, // Store taskId for tracking
      );

      setState(() {
        _songResult = result;
        _statusMessage = 'Processing your song... You\'ll be notified when it\'s ready!';
      });

      Logger.log('Music generation started with taskId: $taskId');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Music generation failed: $e';
        _currentState = VoiceRecordingState.error;
      });
      Logger.log('Music generation error: $e');
      widget.onError?.call();
    }
  }

  // Keep the old method for backward compatibility
  Future<void> _processSong() async {
    // Direct to new workflow
    await _uploadAndConvertToWav();
  }

  void _resetRecording() {
    setState(() {
      _currentState = VoiceRecordingState.idle;
      _recordingDuration = Duration.zero;
      _statusMessage = null;
      _songResult = null;
      _isProcessing = false;

      // Reset WAV conversion states
      _wavConversionResult = null;
      _wavStatus = null;
      _isPollingWavStatus = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _audioService.dispose();
    _aiVoiceService.dispose();
    super.dispose();
  }
}