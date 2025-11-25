import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_music_service.dart';
import '../models/ai_track.dart';
import '../widgets/glassmorphic_card.dart';
import '../services/audio_player_service.dart';
import '../services/track_database_service.dart';
import '../utils/logger.dart';

class TrackListWidget extends StatefulWidget {
  const TrackListWidget({Key? key}) : super(key: key);

  // Add a GlobalKey to access the state
  static final GlobalKey<_TrackListWidgetState> globalKey = GlobalKey<_TrackListWidgetState>();

  @override
  State<TrackListWidget> createState() => _TrackListWidgetState();
}

class _TrackListWidgetState extends State<TrackListWidget> {
  final List<AITrack> _tracks = [];
  String _sortBy = 'date_created';
  String _filterGenre = 'All';
  bool _isGridView = false;
  bool _isLoading = true;

  // Services
  late final AudioPlayerService _audioPlayerService;
  late final TrackDatabaseService _databaseService;
  AITrack? _currentlyPlayingTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = AudioPlayerServiceSingleton().audioPlayerService;
    _databaseService = TrackDatabaseService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeAudioPlayer();
    await _initializeDatabase();
    await _loadTracks();
  }

  Future<void> _initializeDatabase() async {
    await _databaseService.initialize();
  }

  Future<void> _loadTracks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final tracks = await _databaseService.getAllTracks();
      setState(() {
        _tracks.clear();
        _tracks.addAll(tracks);
        _isLoading = false;
      });

      Logger.log('✅ Loaded ${tracks.length} tracks from database');

      // Set up real-time updates for webhook completion
      _setupRealTimeUpdates();
    } catch (e) {
      Logger.log('❌ Error loading tracks: $e');
      setState(() {
        _tracks.clear();
        _isLoading = false;
      });
    }
  }

  /// Setup real-time database updates to automatically refresh when tracks are completed via webhook
  void _setupRealTimeUpdates() {
    // Refresh tracks every 10 seconds to catch webhook updates
    // In production, you might want to use Supabase real-time subscriptions
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final updatedTracks = await _databaseService.getAllTracks();

        // Check if there are new completed tracks
        final hasNewCompletedTracks = updatedTracks.any((track) =>
          track.processingCompleted &&
          !_tracks.any((existingTrack) => existingTrack.id == track.id && existingTrack.processingCompleted)
        );

        if (hasNewCompletedTracks) {
          Logger.log('🔄 Detected completed tracks via webhook, refreshing UI');
          setState(() {
            _tracks.clear();
            _tracks.addAll(updatedTracks);
          });
        }
      } catch (e) {
        Logger.log('❌ Error during real-time update: $e');
      }
    });
  }

  // Public refresh method that can be called from outside
  Future<void> refreshTracks() async {
    await _loadTracks();
  }

  // Public method to add a track (for processing tracks)
  void addTrack(AITrack track) {
    setState(() {
      // Remove any existing track with same ID (in case of updates)
      _tracks.removeWhere((t) => t.id == track.id);
      // Add new/updated track at the beginning
      _tracks.insert(0, track);
    });
  }

  Future<void> _initializeAudioPlayer() async {
    await _audioPlayerService.initialize();

    // Set up listeners
    _audioPlayerService.setPlayingStateListener((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
        if (isPlaying) {
          _currentlyPlayingTrack = _audioPlayerService.currentTrack;
        }
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
  }

  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with filters and view toggle
        _buildHeader(),

        const SizedBox(height: 16),

        // Track list/grid
        Expanded(
          child: _isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search your music library...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white60,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
              filled: true,
              fillColor: const Color(0xFF252641).withOpacity(0.5),
              hintStyle: TextStyle(color: Colors.white38),
            ),
            style: TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 16),

          // Filters and view toggle
          Row(
            children: [
              // Sort dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252641).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1B3A),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                      items: [
                        'Date Created',
                        'Title',
                        'Genre',
                        'Duration',
                      ].map((sort) {
                        return DropdownMenuItem(
                          value: sort.toLowerCase().replaceAll(' ', '_'),
                          child: Text(
                            'Sort by $sort',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Genre filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252641).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterGenre,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1B3A),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                      items: [
                        'All',
                        'Pop',
                        'Electronic',
                        'Rock',
                        'Jazz',
                        'Classical',
                        'Hip Hop',
                      ].map((genre) {
                        return DropdownMenuItem(
                          value: genre,
                          child: Text(
                            genre == 'All' ? 'All Genres' : genre,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _filterGenre = value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252641).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewButton(
                      Icons.view_list_rounded,
                      !_isGridView,
                      () => setState(() => _isGridView = false),
                    ),
                    _buildViewButton(
                      Icons.grid_view_rounded,
                      _isGridView,
                      () => setState(() => _isGridView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white60,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TrackTile(
            track: track,
            onTap: () => _showTrackDetails(track),
            onPlay: () => _playTrack(track),
            onDelete: () => _deleteTrack(track),
            isCurrentlyPlaying: _currentlyPlayingTrack?.id == track.id,
            isPlaying: _isPlaying && _currentlyPlayingTrack?.id == track.id,
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return TrackCard(
          track: track,
          onTap: () => _showTrackDetails(track),
          onPlay: () => _playTrack(track),
          isCurrentlyPlaying: _currentlyPlayingTrack?.id == track.id,
          isPlaying: _isPlaying && _currentlyPlayingTrack?.id == track.id,
        );
      },
    );
  }

  void _showTrackDetails(AITrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrackDetailsSheet(
        track: track,
        onPlay: () => _playTrack(track),
      ),
    );
  }

  Future<void> _playTrack(AITrack track) async {
    try {
      setState(() {
        _currentlyPlayingTrack = track;
      });

      // If this track is already playing, toggle play/pause
      if (_audioPlayerService.currentTrack?.id == track.id) {
        await _audioPlayerService.togglePlayPause();
        return;
      }

      // Play the new track
      await _audioPlayerService.playTrack(track);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now playing: ${track.title}'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing track: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteTrack(AITrack track) {
    setState(() {
      _tracks.removeWhere((t) => t.id == track.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted: ${track.title}'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  final AITrack track;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final bool isCurrentlyPlaying;
  final bool isPlaying;

  const TrackTile({
    Key? key,
    required this.track,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
    this.isCurrentlyPlaying = false,
    this.isPlaying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Album art placeholder with processing indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: track.isProcessing
                  ? [
                      const Color(0xFF6B7280),
                      const Color(0xFF4B5563),
                    ].map((color) => color.withOpacity(0.8)).toList()
                  : [
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ].map((color) => color.withOpacity(0.8)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: track.isProcessing
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Icon(
                      Icons.music_note,
                      color: Colors.white.withOpacity(0.3),
                      size: 16,
                    ),
                  ],
                )
              : Icon(
                  track.isInstrumental ? Icons.music_note : Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
          ),

          const SizedBox(width: 16),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: track.isProcessing ? Colors.white70 : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (track.isProcessing && track.processingStatus != null)
                  Text(
                    track.processingStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
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
                    Icon(
                      track.isProcessing ? Icons.hourglass_empty : Icons.schedule_rounded,
                      size: 12,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      track.isProcessing ? 'Processing...' : _formatDuration(track.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    if (!track.isProcessing) ...[
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
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: track.isProcessing
                    ? Colors.grey.withOpacity(0.2)
                    : isCurrentlyPlaying
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: track.isProcessing ? null : onPlay,
                  icon: Icon(
                    track.isProcessing
                      ? Icons.hourglass_empty
                      : isCurrentlyPlaying && isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: track.isProcessing
                      ? Colors.grey
                      : const Color(0xFF8B5CF6),
                    size: 28,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      onDelete();
                      break;
                    case 'share':
                      // TODO: Implement sharing
                      break;
                    case 'export':
                      // TODO: Implement export
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('Export'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red[300]),
                        const SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrackCard extends StatelessWidget {
  final AITrack track;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final bool isCurrentlyPlaying;
  final bool isPlaying;

  const TrackCard({
    Key? key,
    required this.track,
    required this.onTap,
    required this.onPlay,
    this.isCurrentlyPlaying = false,
    this.isPlaying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: Container(
                width: double.infinity,
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
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        track.isInstrumental ? Icons.music_note : Icons.mic_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onPlay,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isCurrentlyPlaying
                              ? const Color(0xFF8B5CF6).withOpacity(0.8)
                              : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCurrentlyPlaying && isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Track info
            Text(
              track.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(track.duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    track.genre,
                    style: TextStyle(
                      fontSize: 9,
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
    );
  }
}

class TrackDetailsSheet extends StatelessWidget {
  final AITrack track;
  final VoidCallback onPlay;

  const TrackDetailsSheet({
    Key? key,
    required this.track,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ].map((color) => color.withOpacity(0.8)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  track.isInstrumental ? Icons.music_note : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Track details
          _buildDetailRow('Genre', track.genre),
          _buildDetailRow('Mood', track.mood),
          _buildDetailRow('Duration', _formatDuration(track.duration)),
          _buildDetailRow('Created', _formatDate(track.createdAt)),
          _buildDetailRow('Type', track.isInstrumental ? 'Instrumental' : 'With Vocals'),

          if (!track.isInstrumental && track.lyrics != null) ...[
            const SizedBox(height: 20),
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252641).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                track.lyrics!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPlay();
                  },
                  icon: Icon(Icons.play_arrow_rounded),
                  label: Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: Share track
                  },
                  icon: Icon(Icons.share_rounded),
                  label: Text('Share'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}