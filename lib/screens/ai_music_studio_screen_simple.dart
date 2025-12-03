import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/voice_recorder_widget.dart';
import '../models/ai_track.dart';
import '../widgets/music_generation_form.dart';
import '../services/ai_music_service.dart';
import '../services/ai_voice_service.dart';
import '../widgets/mini_player_widget.dart';
import '../widgets/track_list_widget.dart';
import '../services/track_database_service.dart';

class AIMusicStudioScreen extends ConsumerStatefulWidget {
  const AIMusicStudioScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIMusicStudioScreen> createState() => _AIMusicStudioScreenState();
}

class _AIMusicStudioScreenState extends ConsumerState<AIMusicStudioScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  bool _isGenerating = false;
  bool _isRecording = false;
  String _generationStatus = "Initializing...";
  String? _generationStep;

  // Services
  late final AIMusicService _aiMusicService;
  late final TrackDatabaseService _databaseService;

  // Generated tracks
  final List<AITrack> _tracks = [];

  @override
  void initState() {
    super.initState();
    _aiMusicService = AIMusicService();
    _databaseService = TrackDatabaseService();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _databaseService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isConfigured = ref.watch(isConfiguredProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F23), // Deep space blue
              Color(0xFF1A1B3A), // Midnight purple
              Color(0xFF252641), // Lighter surface
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(settings, isConfigured),
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 8),
              // Mini Player (only visible when music is playing)
              const MiniPlayerWidget(),
              const SizedBox(height: 8),
              Expanded(
                child: _buildCurrentTab(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(SettingsState settings, bool isConfigured) {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Music Studio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isConfigured
                        ? 'Powered by AI • Ready to create'
                        : 'Configure API keys to start creating',
                      style: TextStyle(
                        fontSize: 14,
                        color: isConfigured
                          ? Colors.white70
                          : Colors.orange[300],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConfigured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: Colors.orange[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Setup Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isGenerating || _isRecording) ...[
            const SizedBox(height: 16),
            _buildStatusIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isGenerating
          ? const Color(0xFF8B5CF6).withOpacity(0.2)
          : const Color(0xFF14B8A6).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGenerating
            ? const Color(0xFF8B5CF6).withOpacity(0.5)
            : const Color(0xFF14B8A6).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isGenerating ? const Color(0xFF8B5CF6) : const Color(0xFF14B8A6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isGenerating ? 'AI Music Generation' : 'Recording Audio...',
                style: TextStyle(
                  fontSize: 16,
                  color: _isGenerating ? const Color(0xFF8B5CF6) : const Color(0xFF14B8A6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_isGenerating && _generationStep != null) ...[
            const SizedBox(height: 8),
            Text(
              _generationStep!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (_isGenerating) ...[
            const SizedBox(height: 4),
            Text(
              '⏳ This may take 30-60 seconds...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton(0, Icons.auto_awesome_rounded, 'Generate'),
          _buildTabButton(1, Icons.mic_rounded, 'Record'),
          _buildTabButton(2, Icons.library_music_rounded, 'Library'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
              ? const Color(0xFF8B5CF6).withOpacity(0.3)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white60,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.white60,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _buildGenerateTab();
      case 1:
        return _buildRecordTab();
      case 2:
        return _buildLibraryTab();
      default:
        return _buildGenerateTab();
    }
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MusicGenerationForm(
        aiMusicService: _aiMusicService,
        onGenerationStart: () {
          setState(() => _isGenerating = true);
        },
        onGenerationComplete: (track) async {
          setState(() {
            _isGenerating = false;
            _tracks.add(track);
          });

          // Save track to database
          try {
            final saved = await _databaseService.saveTrack(track);
            if (saved) {
              _showSuccessSnackbar('Music generated and saved: ${track.title}');
            } else {
              _showSuccessSnackbar('Music generated (demo mode): ${track.title}');
            }
          } catch (e) {
            _showSuccessSnackbar('Music generated: ${track.title}');
          }
        },
        onGenerationError: (error) {
          setState(() => _isGenerating = false);
          _showErrorSnackbar('Generation failed: $error');
        },
      ),
    );
  }

  Widget _buildRecordTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: VoiceRecorderWidget(
        onSongGenerated: (songResult) async {
          // Convert to AITrack and save to library
          final aiTrack = AITrack(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Voice Song - ${songResult.analysis.mood}',
            artist: 'AI Generated',
            genre: songResult.analysis.genre,
            mood: songResult.analysis.mood,
            duration: const Duration(minutes: 3),
            audioUrl: songResult.backgroundMusicUrl,
            coverArtUrl: '',
            createdAt: DateTime.now(),
            isInstrumental: false,
            metadata: {
              'original_voice': songResult.originalVoiceRecording,
              'transcribed_lyrics': songResult.transcribedLyrics,
              'completed_lyrics': songResult.completedLyrics,
              'voice_analysis': {
                'mood': songResult.analysis.mood,
                'genre': songResult.analysis.genre,
                'tempo': songResult.analysis.tempo,
                'confidence': songResult.analysis.confidence,
              },
              'ai_generated': true,
              'voice_to_song': true,
            },
          );

          // Save to database
          try {
            final saved = await _databaseService.saveTrack(aiTrack);
            if (saved) {
              _showSuccessSnackbar('🎤 Voice song created and saved: ${aiTrack.title}');
            } else {
              _showSuccessSnackbar('🎤 Voice song created (demo mode): ${aiTrack.title}');
            }
          } catch (e) {
            _showSuccessSnackbar('🎤 Voice song created: ${aiTrack.title}');
          }

          // Add to tracks list
          setState(() {
            _tracks.add(aiTrack);
          });

          // Refresh library tab
          try {
            TrackListWidget.globalKey.currentState?.refreshTracks();
          } catch (e) {
            print('Failed to refresh library: $e');
          }
        },
        onError: () {
          _showErrorSnackbar('Voice recording failed. Please try again.');
        },
      ),
    );
  }

  Widget _buildLibraryTab() {
    return const TrackListWidget();
  }

  Widget _buildTrackTile(AITrack track) {
    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ].map((color) => color.withOpacity(0.8)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              track.isInstrumental ? Icons.music_note : Icons.mic_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${track.artist} • ${track.genre}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(track.duration),
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        track.mood,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _playTrack(track),
            icon: Icon(Icons.play_arrow_rounded, color: const Color(0xFF8B5CF6), size: 28),
          ),
        ],
      ),
    );
  }


  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onFabPressed,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _onFabPressed() {
    switch (_currentTab) {
      case 0:
        _generateMusic();
        break;
      case 1:
        _showMessage('Use the voice recorder below to record and generate songs!', const Color(0xFF14B8A6));
        break;
      case 2:
        _showImportDialog();
        break;
    }
  }

  Future<void> _generateMusic() async {
    final settings = ref.read(settingsProvider);
    if (!settings.isFullyConfigured) {
      _showErrorSnackbar('Please configure API keys in settings first');
      return;
    }

    // Music generation parameters
    final prompt = "Create an amazing AI-generated track";
    final genre = 'pop';
    final mood = 'energetic';
    final language = 'english';
    final duration = 30; // Will be replaced with actual duration from UI controls later
    final model = 'V5';

    setState(() {
      _isGenerating = true;
      _generationStatus = "Connecting to AI service...";
      _generationStep = null;
    });

    // Add processing track to library immediately
    String? processingId;
    try {
      processingId = await _databaseService.addProcessingTrack(
        prompt, genre, mood, language, duration
      );
    } catch (e) {
      _showErrorSnackbar('Failed to create processing track: $e');
    }

    try {
      // Update status step by step and processing track
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _generationStatus = "Preparing your request...";
        _generationStep = "✓ Validating parameters";
      });
      if (processingId != null) {
        await _databaseService.updateProcessingStatus(processingId, "Validating parameters...");
      }

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _generationStatus = "Sending to AI model...";
        _generationStep = "✓ Request sent to AI API";
      });
      if (processingId != null) {
        await _databaseService.updateProcessingStatus(processingId, "Sending to AI API...");
      }

      // Call the real AI music service with actual parameters
      final track = await _aiMusicService.generateMusic(
        prompt: prompt,
        genre: genre,
        mood: mood,
        language: language,
        duration: duration,
        model: model,
      );

      setState(() {
        _generationStatus = "Processing response...";
        _generationStep = "✓ AI response received";
      });
      if (processingId != null) {
        await _databaseService.updateProcessingStatus(processingId, "Processing AI response...");
      }

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _generationStatus = "Saving to library...";
        _generationStep = "✓ Adding to your collection";
      });
      if (processingId != null) {
        await _databaseService.updateProcessingStatus(processingId, "Saving to library...");
      }

      // Convert GeneratedTrack to AITrack
      final aiTrack = AITrack(
        id: track.id,
        title: track.title,
        artist: track.artist,
        genre: track.genre,
        mood: track.mood,
        duration: Duration(seconds: track.duration),
        audioUrl: track.audioUrl,
        coverArtUrl: track.coverImageUrl,
        createdAt: track.createdAt,
        isInstrumental: track.metadata['instrumental'] ?? false,
        metadata: track.metadata,
      );

      // Convert processing track to completed track
      if (processingId != null) {
        await _databaseService.completeProcessingTrack(processingId, aiTrack);
      } else {
        // Fallback to normal save if processing track wasn't created
        await _databaseService.saveTrack(aiTrack);
      }

      setState(() {
        _isGenerating = false;
        _tracks.add(aiTrack);
        _generationStatus = "Complete!";
        _generationStep = null;
      });

      // Refresh the Library tab to show the new track
      try {
        TrackListWidget.globalKey.currentState?.refreshTracks();
      } catch (e) {
        // Refresh failed, but track was still saved
        print('Failed to refresh library: $e');
      }

      _showSuccessSnackbar('AI music generated successfully! 🎵');
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = "Error occurred";
        _generationStep = "❌ " + e.toString();
      });

      // Remove processing track on error
      if (processingId != null) {
        await _databaseService.removeProcessingTrack(processingId);
      }

      _showErrorSnackbar('Failed to generate music: ${e.toString()}');
    }
  }

  void _playTrack(AITrack track) {
    _showSuccessSnackbar('Playing: ${track.title}');
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text('Import Music', style: TextStyle(color: Colors.white)),
        content: const Text('Import functionality coming soon!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}