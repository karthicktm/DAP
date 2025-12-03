import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/voice_recorder_widget.dart';
import '../services/ai_voice_service.dart';
import '../services/audio_service.dart';
import '../utils/logger.dart';

/// Voice to Song screen - Record voice, generate lyrics, create background music
class VoiceToSongScreen extends ConsumerStatefulWidget {
  const VoiceToSongScreen({super.key});

  @override
  ConsumerState<VoiceToSongScreen> createState() => _VoiceToSongScreenState();
}

class _VoiceToSongScreenState extends ConsumerState<VoiceToSongScreen> {
  CompleteSongResult? _currentSong;
  bool _isPlayingVoice = false;
  bool _isPlayingMusic = false;
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Voice to Song AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1B3A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_currentSong != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSong,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildVoiceRecorderSection(),
            if (_currentSong != null) ...[
              const SizedBox(height: 32),
              _buildSongResultSection(),
            ],
            const SizedBox(height: 32),
            _buildHowItWorksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Voice to Song Creator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Record your voice singing or speaking lyrics, and AI will:\n• Transcribe your words to text\n• Detect mood and genre\n• Complete missing lyrics\n• Generate background music\n• Create a full song',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecorderSection() {
    return VoiceRecorderWidget(
      onSongGenerated: (songResult) {
        setState(() {
          _currentSong = songResult;
        });
        _showSongGeneratedDialog();
      },
      onError: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildSongResultSection() {
    if (_currentSong == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generated Song',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Song Analysis Card
        _buildAnalysisCard(),
        const SizedBox(height: 16),

        // Lyrics Card
        _buildLyricsCard(),
        const SizedBox(height: 16),

        // Audio Players Card
        _buildAudioPlayersCard(),
        const SizedBox(height: 16),

        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  'Mood',
                  _currentSong!.analysis.mood,
                  Icons.mood,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildAnalysisItem(
                  'Genre',
                  _currentSong!.analysis.genre,
                  Icons.music_note,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  'Tempo',
                  _currentSong!.analysis.tempo,
                  Icons.speed,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildAnalysisItem(
                  'Confidence',
                  '${(_currentSong!.analysis.confidence * 100).toInt()}%',
                  Icons.verified,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lyrics, color: Color(0xFF14B8A6)),
              SizedBox(width: 8),
              Text(
                'Lyrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original vs Completed tabs
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Your Voice'),
                    Tab(text: 'AI Completed'),
                  ],
                  labelColor: const Color(0xFF14B8A6),
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  indicatorColor: const Color(0xFF14B8A6),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: TabBarView(
                    children: [
                      _buildLyricsText(_currentSong!.transcribedLyrics),
                      _buildLyricsText(_currentSong!.completedLyrics),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsText(String lyrics) {
    return SingleChildScrollView(
      child: Text(
        lyrics.isEmpty ? 'No lyrics detected' : lyrics,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.9),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildAudioPlayersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.audiotrack, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Audio Tracks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original Voice Player
          _buildAudioPlayerTile(
            title: 'Your Original Voice',
            subtitle: 'The voice recording you made',
            icon: Icons.record_voice_over,
            isPlaying: _isPlayingVoice,
            onPlay: _playOriginalVoice,
            onStop: _stopOriginalVoice,
          ),

          const SizedBox(height: 12),

          // Background Music Player
          _buildAudioPlayerTile(
            title: 'AI Generated Background Music',
            subtitle: 'Instrumental music matching your voice',
            icon: Icons.music_note,
            isPlaying: _isPlayingMusic,
            onPlay: _playBackgroundMusic,
            onStop: _stopBackgroundMusic,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPlaying,
    required VoidCallback onPlay,
    required VoidCallback onStop,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            color: Colors.orange,
            onPressed: isPlaying ? onStop : onPlay,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveSong,
                icon: const Icon(Icons.save),
                label: const Text('Save Song'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloadSong,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createNewSong,
            icon: const Icon(Icons.add),
            label: const Text('Create Another Song'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHowItWorksStep(1, 'Record Your Voice', 'Sing or speak your lyrics into the microphone'),
          _buildHowItWorksStep(2, 'AI Analysis', 'AI transcribes speech and detects mood, genre, tempo'),
          _buildHowItWorksStep(3, 'Lyrics Completion', 'AI fills in missing lyrics and improves structure'),
          _buildHowItWorksStep(4, 'Music Generation', 'AI creates background music matching your style'),
          _buildHowItWorksStep(5, 'Complete Song', 'Combine your voice with AI-generated music'),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSongGeneratedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          '🎉 Song Generated!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI song has been generated successfully!\n\nMood: ${_currentSong?.analysis.mood}\nGenre: ${_currentSong?.analysis.genre}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _playOriginalVoice() async {
    try {
      if (_currentSong?.originalVoiceRecording != null) {
        await _audioService.loadLocalAudio(_currentSong!.originalVoiceRecording);
        await _audioService.play();
        setState(() => _isPlayingVoice = true);
      }
    } catch (e) {
      Logger.log('Error playing original voice: $e');
    }
  }

  void _stopOriginalVoice() async {
    await _audioService.stop();
    setState(() => _isPlayingVoice = false);
  }

  void _playBackgroundMusic() async {
    try {
      if (_currentSong?.backgroundMusicUrl != null) {
        await _audioService.loadAudio(_currentSong!.backgroundMusicUrl);
        await _audioService.play();
        setState(() => _isPlayingMusic = true);
      }
    } catch (e) {
      Logger.log('Error playing background music: $e');
    }
  }

  void _stopBackgroundMusic() async {
    await _audioService.stop();
    setState(() => _isPlayingMusic = false);
  }

  void _saveSong() {
    // Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song saved to your library!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadSong() {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading song...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareSong() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _createNewSong() {
    setState(() {
      _currentSong = null;
      _isPlayingVoice = false;
      _isPlayingMusic = false;
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}