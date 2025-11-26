import 'package:flutter/material.dart';
import 'dart:async';
import '../services/live_radio_service.dart';
import '../models/ai_track.dart';
import '../widgets/glassmorphic_card.dart';

class LiveRadioWidget extends StatefulWidget {
  const LiveRadioWidget({Key? key}) : super(key: key);

  @override
  State<LiveRadioWidget> createState() => _LiveRadioWidgetState();
}

class _LiveRadioWidgetState extends State<LiveRadioWidget>
    with TickerProviderStateMixin {
  final LiveRadioService _radioService = LiveRadioService();
  StreamSubscription<AITrack>? _radioSubscription;

  bool _isPlaying = false;
  String _selectedMood = 'balanced';
  AITrack? _currentTrack;
  RadioContext? _currentContext;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  final List<String> _moods = [
    'balanced', 'energetic', 'relaxed', 'focused', 'happy', 'melancholy'
  ];

  final Map<String, IconData> _moodIcons = {
    'balanced': Icons.balance,
    'energetic': Icons.flash_on,
    'relaxed': Icons.spa,
    'focused': Icons.center_focus_strong,
    'happy': Icons.sentiment_very_satisfied,
    'melancholy': Icons.sentiment_neutral,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadCurrentContext();
  }

  @override
  void dispose() {
    _stopRadio();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentContext() async {
    final context = await _radioService.getUserContext();
    setState(() {
      _currentContext = context;
    });
  }

  void _startRadio() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    _pulseController.repeat();
    _waveController.repeat();

    final radioStream = _radioService.startLiveRadio(mood: _selectedMood);
    _radioSubscription = radioStream.listen(
      (track) {
        setState(() {
          _currentTrack = track;
        });
        _showNewTrackSnackbar(track);
      },
      onError: (error) {
        _showErrorSnackbar('Radio error: $error');
      },
    );
  }

  void _stopRadio() {
    setState(() {
      _isPlaying = false;
      _currentTrack = null;
    });

    _pulseController.stop();
    _waveController.stop();

    _radioSubscription?.cancel();
    _radioService.stopLiveRadio();
  }

  void _changeMood(String newMood) {
    setState(() {
      _selectedMood = newMood;
    });

    if (_isPlaying) {
      _stopRadio();
      Future.delayed(const Duration(milliseconds: 500), () {
        _startRadio();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildContextInfo(),
          const SizedBox(height: 20),
          _buildMoodSelector(),
          const SizedBox(height: 20),
          _buildRadioVisualizer(),
          const SizedBox(height: 20),
          _buildCurrentTrackInfo(),
          const SizedBox(height: 20),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            Icons.radio,
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
                'Live AI Radio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Contextual music for your time & mood',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextInfo() {
    if (_currentContext == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 ${_currentContext!.region} • ${_currentContext!.timezone}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🕐 ${_currentContext!.localTime} • ${_currentContext!.timeOfDay.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 ${_currentContext!.dayOfWeek}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Mood',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => _changeMood(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withOpacity(0.3)
                      : const Color(0xFF1A1B3A).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF8B5CF6).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _moodIcons[mood] ?? Icons.sentiment_neutral,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mood.capitalize(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withOpacity(0.7),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadioVisualizer() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: _isPlaying ? _buildActiveVisualizer() : _buildInactiveVisualizer(),
      ),
    );
  }

  Widget _buildActiveVisualizer() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final height = 20 + (40 * (0.5 + 0.5 *
                (1 + index * 0.2 * _waveController.value).clamp(0.0, 1.0)));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInactiveVisualizer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.radio,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'Press play to start live radio',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTrackInfo() {
    if (_currentTrack == null) {
      return Container(
        height: 60,
        child: Center(
          child: Text(
            _isPlaying ? 'Generating your first track...' : 'No track playing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTrack!.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentTrack!.genre} • ${_currentTrack!.mood}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
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
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _isPlaying
                ? 1.0 + (_pulseController.value * 0.1)
                : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPlaying
                        ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isPlaying ? _stopRadio : _startRadio,
                    borderRadius: BorderRadius.circular(36),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNewTrackSnackbar(AITrack track) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🎵 Now playing: ${track.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
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
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}