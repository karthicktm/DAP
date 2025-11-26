import 'dart:async';
import 'dart:math';
import '../models/ai_track.dart';
import 'ai_music_service.dart';
import 'package:intl/intl.dart';

/// Live Radio Service that generates contextual music streams
/// Based on user's timezone, local time, and mood preferences
class LiveRadioService {
  final AIMusicService _aiMusicService = AIMusicService();
  StreamController<AITrack>? _streamController;
  Timer? _scheduleTimer;
  bool _isStreaming = false;

  /// Get user's current context for radio programming
  Future<RadioContext> getUserContext() async {
    final now = DateTime.now();
    final timeOfDay = _getTimeOfDay(now);
    final timezone = now.timeZoneName;

    return RadioContext(
      timezone: timezone,
      localTime: DateFormat('HH:mm').format(now),
      timeOfDay: timeOfDay,
      hour: now.hour,
      dayOfWeek: DateFormat('EEEE').format(now),
      region: _getRegionFromTimezone(timezone),
    );
  }

  /// Start live radio stream based on current context
  Stream<AITrack> startLiveRadio({String mood = 'balanced'}) {
    _streamController = StreamController<AITrack>.broadcast();
    _isStreaming = true;

    _scheduleNextTrack(mood);

    return _streamController!.stream;
  }

  /// Stop the live radio stream
  void stopLiveRadio() {
    _isStreaming = false;
    _scheduleTimer?.cancel();
    _streamController?.close();
  }

  /// Schedule the next track based on context and mood
  Future<void> _scheduleNextTrack(String userMood) async {
    if (!_isStreaming) return;

    try {
      final context = await getUserContext();
      final track = await _generateContextualTrack(context, userMood);

      _streamController?.add(track);

      // Schedule next track (3-5 minutes from now)
      final nextTrackDelay = Duration(
        seconds: 180 + Random().nextInt(120), // 3-5 minutes
      );

      _scheduleTimer = Timer(nextTrackDelay, () {
        _scheduleNextTrack(userMood);
      });

    } catch (e) {
      print('Error generating radio track: $e');
      // Retry in 30 seconds
      _scheduleTimer = Timer(Duration(seconds: 30), () {
        _scheduleNextTrack(userMood);
      });
    }
  }

  /// Generate a track based on current context and user mood
  Future<AITrack> _generateContextualTrack(RadioContext context, String userMood) async {
    final prompt = _buildContextualPrompt(context, userMood);
    final genre = _selectGenreForContext(context, userMood);
    final style = _selectStyleForContext(context);

    print('🎵 Live Radio: Generating ${context.timeOfDay} track for $userMood mood');

    return await _aiMusicService.generateMusic(
      prompt: prompt,
      genre: genre,
      mood: _combineMoods(context.timeOfDay, userMood),
      style: style,
      duration: 180, // 3 minutes per track
      model: 'V5',
      language: 'english',
    );
  }

  /// Build contextual prompt based on time and region
  String _buildContextualPrompt(RadioContext context, String userMood) {
    final timePrompts = {
      'morning': 'Energizing morning music to start the day, coffee shop vibes',
      'midday': 'Focus and productivity music, ambient background',
      'afternoon': 'Motivational afternoon energy, uplifting melodies',
      'evening': 'Relaxing evening wind-down, dinner ambiance',
      'night': 'Chill night vibes, atmospheric and calm',
      'late_night': 'Late night deep focus, minimal and hypnotic',
    };

    final basePrompt = timePrompts[context.timeOfDay] ?? 'Ambient background music';

    // Add regional flavor
    final regionalPrompt = _getRegionalMusicStyle(context.region);

    // Add mood enhancement
    final moodPrompt = _getMoodPrompt(userMood);

    return '$basePrompt, $regionalPrompt, $moodPrompt';
  }

  /// Select genre based on context
  String _selectGenreForContext(RadioContext context, String userMood) {
    final timeGenres = {
      'morning': ['pop', 'indie', 'acoustic'],
      'midday': ['ambient', 'electronic', 'instrumental'],
      'afternoon': ['rock', 'alternative', 'upbeat'],
      'evening': ['jazz', 'lounge', 'soft rock'],
      'night': ['ambient', 'chillout', 'downtempo'],
      'late_night': ['ambient', 'minimal', 'drone'],
    };

    final genres = timeGenres[context.timeOfDay] ?? ['ambient'];
    return genres[Random().nextInt(genres.length)];
  }

  /// Select style based on context
  String _selectStyleForContext(RadioContext context) {
    final timeStyles = {
      'morning': 'modern',
      'midday': 'minimalist',
      'afternoon': 'energetic',
      'evening': 'sophisticated',
      'night': 'atmospheric',
      'late_night': 'ethereal',
    };

    return timeStyles[context.timeOfDay] ?? 'modern';
  }

  /// Determine time of day from current hour
  String _getTimeOfDay(DateTime now) {
    final hour = now.hour;

    if (hour >= 5 && hour < 10) return 'morning';
    if (hour >= 10 && hour < 14) return 'midday';
    if (hour >= 14 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    if (hour >= 22 || hour < 2) return 'night';
    return 'late_night'; // 2-5 AM
  }

  /// Get region from timezone
  String _getRegionFromTimezone(String timezone) {
    if (timezone.contains('America')) return 'Americas';
    if (timezone.contains('Europe')) return 'Europe';
    if (timezone.contains('Asia')) return 'Asia';
    if (timezone.contains('Australia')) return 'Oceania';
    return 'Global';
  }

  /// Get regional music style influences
  String _getRegionalMusicStyle(String region) {
    final regionalStyles = {
      'Americas': 'with American rock and country influences',
      'Europe': 'with European electronic and classical elements',
      'Asia': 'with Asian traditional and modern fusion elements',
      'Oceania': 'with indie and surf rock influences',
      'Global': 'with world music fusion',
    };

    return regionalStyles[region] ?? 'with modern production';
  }

  /// Get mood enhancement prompts
  String _getMoodPrompt(String mood) {
    final moodPrompts = {
      'energetic': 'high energy and motivational',
      'relaxed': 'calm and soothing',
      'focused': 'minimal and concentration-friendly',
      'happy': 'uplifting and joyful',
      'melancholy': 'introspective and emotional',
      'balanced': 'well-balanced and versatile',
    };

    return moodPrompts[mood] ?? 'balanced and pleasant';
  }

  /// Combine time-based mood with user mood
  String _combineMoods(String timeOfDay, String userMood) {
    // Morning + Relaxed = Gentle Energy
    // Evening + Energetic = Uplifting Calm
    // etc.

    if (timeOfDay == 'morning' && userMood == 'relaxed') return 'gentle';
    if (timeOfDay == 'evening' && userMood == 'energetic') return 'uplifting';
    if (timeOfDay == 'night' && userMood == 'energetic') return 'chill';

    return userMood; // Default to user preference
  }
}

/// Radio context data class
class RadioContext {
  final String timezone;
  final String localTime;
  final String timeOfDay;
  final int hour;
  final String dayOfWeek;
  final String region;

  RadioContext({
    required this.timezone,
    required this.localTime,
    required this.timeOfDay,
    required this.hour,
    required this.dayOfWeek,
    required this.region,
  });

  @override
  String toString() {
    return 'RadioContext(time: $localTime, timeOfDay: $timeOfDay, region: $region, timezone: $timezone)';
  }
}