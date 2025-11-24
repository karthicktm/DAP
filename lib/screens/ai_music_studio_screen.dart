import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_music_service.dart';
import '../services/audio_service.dart';
import '../services/track_database_service.dart';
import '../providers/settings_provider.dart';
import '../models/ai_track.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/audio_waveform_widget.dart';
import '../widgets/music_generation_form.dart';
import '../widgets/track_list_widget.dart';

class AIMusicStudioScreen extends ConsumerStatefulWidget {
  const AIMusicStudioScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIMusicStudioScreen> createState() => _AIMusicStudioScreenState();
}

class _AIMusicStudioScreenState extends ConsumerState<AIMusicStudioScreen>
    with TickerProviderStateMixin {
  late AnimationController _tabController;
  late AnimationController _fabController;
  late Animation<double> _fabRotation;
  int _currentTab = 0;
  bool _isGenerating = false;
  bool _isRecording = false;

  // Services
  late AIMusicService _aiMusicService;
  late AudioService _audioService;
  late TrackDatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabRotation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _aiMusicService = AIMusicService();
      _audioService = AudioService();
      _databaseService = TrackDatabaseService();

      // Initialize services
      await _databaseService.initialize();

      // Audio service is initialized in its constructor

      setState(() {});
    } catch (e) {
      _showErrorSnackbar('Failed to initialize services: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    _audioService.dispose();
    super.dispose();
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
              const SizedBox(height: 16),
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
                        ? 'Powered by kie.ai • Ready to create'
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
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isGenerating ? const Color(0xFF8B5CF6) : const Color(0xFF14B8A6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isGenerating ? 'Generating AI Music...' : 'Recording Audio...',
            style: TextStyle(
              fontSize: 14,
              color: _isGenerating ? const Color(0xFF8B5CF6) : const Color(0xFF14B8A6),
              fontWeight: FontWeight.w500,
            ),
          ),
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
            _tabController.animateTo(index.toDouble());
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Actions
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        Icons.speed_rounded,
                        'Instant Music',
                        'Generate in 30s',
                        const Color(0xFF8B5CF6),
                        () => _generateInstantMusic(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        Icons.auto_awesome_motion_rounded,
                        'Custom Style',
                        'Your unique sound',
                        const Color(0xFFEC4899),
                        () => _showCustomGenerationDialog(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Music Generation Form
          Expanded(
            child: MusicGenerationForm(
              aiMusicService: _aiMusicService,
              onGenerationStart: () => setState(() => _isGenerating = true),
              onGenerationComplete: (track) async {
                setState(() => _isGenerating = false);

                // Add track to library immediately (for processing state)
                TrackListWidget.globalKey.currentState?.addTrack(track);

                // Save track to database if it's completed
                if (!track.isProcessing) {
                  try {
                    final saved = await _databaseService.saveTrack(track);
                    if (saved) {
                      _showSuccessSnackbar('Music generated and saved: ${track.title}');
                    } else {
                      _showSuccessSnackbar('Music generated (demo mode): ${track.title}');
                    }

                    // Refresh the track list to sync with database
                    TrackListWidget.globalKey.currentState?.refreshTracks();
                  } catch (e) {
                    _showSuccessSnackbar('Music generated: ${track.title}');
                  }
                } else {
                  // For processing tracks, just show immediate feedback
                  _showInfoSnackbar('🎵 Generating: ${track.title}');
                }
              },
              onGenerationError: (error) {
                setState(() => _isGenerating = false);
                _showErrorSnackbar('Generation failed: $error');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Recording Interface
          GlassmorphicCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Audio Recording Studio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'High-quality recording with real-time waveform',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),

                // Waveform Display
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B3A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AudioWaveformWidget(
                    audioService: _audioService,
                    height: 120,
                    isRecording: _isRecording,
                  ),
                ),

                const SizedBox(height: 24),

                // Recording Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRecordButton(),
                    _buildPlayButton(),
                    _buildStopButton(),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recording Settings
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingItem('Quality', 'High (44.1kHz)', Icons.high_quality),
                _buildSettingItem('Format', 'WAV', Icons.audio_file),
                _buildSettingItem('Channels', 'Stereo', Icons.surround_sound),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: TrackListWidget(key: TrackListWidget.globalKey),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: _isRecording
          ? const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
            )
          : const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
            ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (_isRecording ? Colors.red : const Color(0xFF14B8A6)).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleRecording,
          borderRadius: BorderRadius.circular(32),
          child: Icon(
            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _playRecording,
          borderRadius: BorderRadius.circular(28),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Color(0xFF8B5CF6),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _stopPlayback,
          borderRadius: BorderRadius.circular(28),
          child: Icon(
            Icons.stop_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _fabRotation.value * 2 * 3.14159,
          child: Container(
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
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onFabPressed() {
    switch (_currentTab) {
      case 0:
        _showCustomGenerationDialog();
        break;
      case 1:
        _toggleRecording();
        break;
      case 2:
        _showImportDialog();
        break;
    }
  }

  Future<void> _generateInstantMusic() async {
    final settings = ref.read(settingsProvider);
    if (!settings.isFullyConfigured) {
      _showErrorSnackbar('Please configure API keys in settings first');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final track = await _aiMusicService.generateMusic(
        prompt: "Upbeat electronic music with modern production",
        genre: "Electronic",
        mood: "Energetic",
        duration: 30,
      );

      setState(() => _isGenerating = false);
      _showSuccessSnackbar('Instant music generated successfully!');
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorSnackbar('Failed to generate music: $e');
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        await _audioService.stopRecording();
        setState(() => _isRecording = false);
        _showSuccessSnackbar('Recording saved successfully!');
      } else {
        await _audioService.startRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      _showErrorSnackbar('Recording failed: $e');
    }
  }

  Future<void> _playRecording() async {
    try {
      await _audioService.play();
    } catch (e) {
      _showErrorSnackbar('Playback failed: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioService.stop();
    } catch (e) {
      _showErrorSnackbar('Stop failed: $e');
    }
  }

  void _showCustomGenerationDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomMusicGenerationDialog(
        aiMusicService: _aiMusicService,
        onGenerate: (prompt, genre, mood, duration) async {
          Navigator.of(context).pop();
          setState(() => _isGenerating = true);

          try {
            final track = await _aiMusicService.generateMusic(
              prompt: prompt,
              genre: genre,
              mood: mood,
              duration: duration,
            );

            setState(() => _isGenerating = false);
            _showSuccessSnackbar('Custom music generated successfully!');
          } catch (e) {
            setState(() => _isGenerating = false);
            _showErrorSnackbar('Generation failed: $e');
          }
        },
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportMusicDialog(
        onImport: (filePath) async {
          Navigator.of(context).pop();
          try {
            await _audioService.loadLocalAudio(filePath);
            _showSuccessSnackbar('Music imported successfully!');
          } catch (e) {
            _showErrorSnackbar('Import failed: $e');
          }
        },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class CustomMusicGenerationDialog extends StatefulWidget {
  final AIMusicService aiMusicService;
  final Function(String prompt, String genre, String mood, int duration) onGenerate;

  const CustomMusicGenerationDialog({
    Key? key,
    required this.aiMusicService,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<CustomMusicGenerationDialog> createState() => _CustomMusicGenerationDialogState();
}

class _CustomMusicGenerationDialogState extends State<CustomMusicGenerationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  String _selectedGenre = 'Electronic';
  String _selectedMood = 'Energetic';
  double _duration = 60;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1B3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Music Generation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Describe your music',
                  hintText: 'e.g., Upbeat electronic music with modern synths and heavy bass',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your music';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Genre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Electronic', 'Pop', 'Rock', 'Jazz', 'Classical', 'Hip Hop']
                    .map((genre) => ChoiceChip(
                      label: Text(genre),
                      selected: _selectedGenre == genre,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedGenre = genre);
                      },
                      backgroundColor: const Color(0xFF252641),
                      selectedColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _selectedGenre == genre ? const Color(0xFF8B5CF6) : Colors.white70,
                      ),
                    ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              Text(
                'Mood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Energetic', 'Relaxing', 'Happy', 'Sad', 'Mysterious', 'Dramatic']
                    .map((mood) => ChoiceChip(
                      label: Text(mood),
                      selected: _selectedMood == mood,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMood = mood);
                      },
                      backgroundColor: const Color(0xFF252641),
                      selectedColor: const Color(0xFFEC4899).withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _selectedMood == mood ? const Color(0xFFEC4899) : Colors.white70,
                      ),
                    ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              Text(
                'Duration: ${_duration.round()}s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Slider(
                value: _duration,
                min: 15,
                max: 300,
                divisions: 19,
                activeColor: const Color(0xFF8B5CF6),
                inactiveColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                onChanged: (value) {
                  setState(() => _duration = value);
                },
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onGenerate(
                          _promptController.text.trim(),
                          _selectedGenre,
                          _selectedMood,
                          _duration.round(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportMusicDialog extends StatelessWidget {
  final Function(String filePath) onImport;

  const ImportMusicDialog({
    Key? key,
    required this.onImport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1B3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import Music',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a music file from your device to import into your library.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImportOption(
                  context,
                  Icons.folder,
                  'Browse Files',
                  () async {
                    // TODO: Implement file picker
                    Navigator.of(context).pop();
                    onImport('/path/to/selected/file.mp3');
                  },
                ),
                _buildImportOption(
                  context,
                  Icons.link,
                  'From URL',
                  () {
                    // TODO: Implement URL input
                    Navigator.of(context).pop();
                    onImport('https://example.com/music.mp3');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252641),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}