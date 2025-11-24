import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../models/ai_track.dart';
import 'glassmorphic_card.dart';

class MiniPlayerWidget extends StatefulWidget {
  const MiniPlayerWidget({Key? key}) : super(key: key);

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  late final AudioPlayerService _audioPlayerService;
  AITrack? _currentTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = AudioPlayerServiceSingleton().audioPlayerService;
    _initializeListeners();
  }

  void _initializeListeners() {
    _audioPlayerService.setPlayingStateListener((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
        _currentTrack = _audioPlayerService.currentTrack;
      });
    });

    _audioPlayerService.setPositionListener((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayerService.setDurationListener((duration) {
      setState(() {
        _currentDuration = duration;
      });
    });

    // Initialize current state
    _currentTrack = _audioPlayerService.currentTrack;
    _isPlaying = _audioPlayerService.isPlaying;
    _currentPosition = _audioPlayerService.currentPosition;
    _currentDuration = _audioPlayerService.currentDuration;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Track info and controls
            Row(
              children: [
                // Album art or placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6),
                        const Color(0xFFEC4899),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _currentTrack?.coverArtUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentTrack!.coverArtUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.music_note,
                              color: Colors.white70,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.music_note,
                        color: Colors.white70,
                        size: 24,
                      ),
                ),

                const SizedBox(width: 12),

                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrack?.title ?? 'Unknown Track',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentTrack?.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Play/Pause button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Stop button
                GestureDetector(
                  onTap: _stop,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stop_rounded,
                      color: Colors.red.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            if (_currentDuration != null)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _audioPlayerService.progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF8B5CF6),
                    ),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _audioPlayerService.formatTime(_currentPosition),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        _audioPlayerService.formatTime(_currentDuration!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlayPause() async {
    await _audioPlayerService.togglePlayPause();
  }

  Future<void> _stop() async {
    await _audioPlayerService.stop();
    setState(() {
      _currentTrack = null;
    });
  }
}