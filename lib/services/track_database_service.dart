import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/ai_track.dart';
import '../utils/logger.dart';
import '../services/secure_storage_service.dart';

/// Track Database Service using Supabase for persistent storage
class TrackDatabaseService {
  static final TrackDatabaseService _instance = TrackDatabaseService._internal();
  factory TrackDatabaseService() => _instance;
  TrackDatabaseService._internal();

  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  /// Initialize Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to get credentials from settings first
      String? supabaseUrl = await SecureStorageService.getSupabaseUrl();
      String? supabaseKey = await SecureStorageService.getSupabaseKey();

      // Fall back to API constants (which may include env vars)
      if (supabaseUrl == null || supabaseKey == null) {
        supabaseUrl = ApiConstants.supabaseUrl;
        supabaseKey = ApiConstants.supabaseAnonKey;
      }

      // Check if we have valid credentials
      if (supabaseUrl == 'your_supabase_url' ||
          supabaseKey == 'your_supabase_anon_key' ||
          supabaseUrl.isEmpty ||
          supabaseKey.isEmpty) {
        Logger.log('Supabase not configured, will use local storage fallback');
        _isInitialized = false;
        return;
      }

      // Initialize Supabase if not already done
      if (Supabase.instance.client == null) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );
      }

      _supabase = Supabase.instance.client;
      _isInitialized = true;

      Logger.log('✅ Supabase initialized successfully with URL: ${supabaseUrl.substring(0, 30)}...');
    } catch (e) {
      Logger.log('❌ Failed to initialize Supabase: $e');
      // Continue with local storage mode if Supabase fails
      _isInitialized = false;
    }
  }

  /// Check if Supabase is properly configured and available
  bool get isSupabaseAvailable {
    return _isInitialized;
  }

  /// Save a generated track to the database
  Future<bool> saveTrack(AITrack track) async {
    if (!isSupabaseAvailable) {
      Logger.log('Supabase not configured, using local storage fallback');
      return _saveTrackLocally(track);
    }

    try {
      final trackData = {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'genre': track.genre,
        'mood': track.mood,
        'audio_url': track.audioUrl,
        'cover_art_url': track.coverArtUrl,
        'duration_seconds': track.duration.inSeconds,
        'is_instrumental': track.isInstrumental,
        'lyrics': track.lyrics,
        'created_at': track.createdAt.toIso8601String(),
        'metadata': track.metadata,
        'user_id': _supabase.auth.currentUser?.id ?? 'anonymous',
      };

      await _supabase.from('tracks').upsert(trackData);
      Logger.log('Track saved to database: ${track.title}');
      return true;
    } catch (e) {
      Logger.log('Error saving track to database: $e');
      return false;
    }
  }

  /// Get all tracks from the database
  Future<List<AITrack>> getAllTracks() async {
    if (!isSupabaseAvailable) {
      Logger.log('Supabase not configured, using local storage fallback');
      return _getLocalTracks();
    }

    try {
      final response = await _supabase
          .from('tracks')
          .select('*')
          .order('created_at', ascending: false);

      final tracks = <AITrack>[];

      for (final trackData in response) {
        try {
          final track = AITrack(
            id: trackData['id']?.toString() ?? '',
            title: trackData['title']?.toString() ?? 'Unknown Track',
            artist: trackData['artist']?.toString() ?? 'AI Artist',
            genre: trackData['genre']?.toString() ?? 'Unknown',
            mood: trackData['mood']?.toString() ?? 'Unknown',
            duration: Duration(
              seconds: trackData['duration_seconds']?.toInt() ?? 120,
            ),
            audioUrl: trackData['audio_url']?.toString() ?? '',
            coverArtUrl: trackData['cover_art_url']?.toString(),
            createdAt: DateTime.tryParse(trackData['created_at']?.toString() ?? '') ?? DateTime.now(),
            isInstrumental: trackData['is_instrumental']?.toString().toLowerCase() == 'true',
            lyrics: trackData['lyrics']?.toString(),
            metadata: Map<String, dynamic>.from(trackData['metadata'] ?? {}),
          );
          tracks.add(track);
        } catch (e) {
          Logger.log('Error parsing track data: $e');
        }
      }

      Logger.log('Loaded ${tracks.length} tracks from database');
      return tracks;
    } catch (e) {
      Logger.log('Error loading tracks from database: $e');
      return [];
    }
  }

  /// Get tracks filtered by genre
  Future<List<AITrack>> getTracksByGenre(String genre) async {
    if (!isSupabaseAvailable) {
      return [];
    }

    try {
      final response = await _supabase
          .from('tracks')
          .select('*')
          .eq('genre', genre)
          .order('created_at', ascending: false);

      final tracks = <AITrack>[];

      for (final trackData in response) {
        final track = AITrack(
          id: trackData['id']?.toString() ?? '',
          title: trackData['title']?.toString() ?? 'Unknown Track',
          artist: trackData['artist']?.toString() ?? 'AI Artist',
          genre: trackData['genre']?.toString() ?? 'Unknown',
          mood: trackData['mood']?.toString() ?? 'Unknown',
          duration: Duration(
            seconds: trackData['duration_seconds']?.toInt() ?? 120,
          ),
          audioUrl: trackData['audio_url']?.toString() ?? '',
          coverArtUrl: trackData['cover_art_url']?.toString(),
          createdAt: DateTime.tryParse(trackData['created_at']?.toString() ?? '') ?? DateTime.now(),
          isInstrumental: trackData['is_instrumental']?.toString().toLowerCase() == 'true',
          lyrics: trackData['lyrics']?.toString(),
          metadata: Map<String, dynamic>.from(trackData['metadata'] ?? {}),
        );
        tracks.add(track);
      }

      return tracks;
    } catch (e) {
      Logger.log('Error loading tracks by genre: $e');
      return [];
    }
  }

  /// Delete a track from the database
  Future<bool> deleteTrack(String trackId) async {
    if (!isSupabaseAvailable) {
      Logger.log('Supabase not configured, cannot delete track');
      return false;
    }

    try {
      await _supabase.from('tracks').delete().eq('id', trackId);
      Logger.log('Track deleted from database: $trackId');
      return true;
    } catch (e) {
      Logger.log('Error deleting track from database: $e');
      return false;
    }
  }

  /// Clear all tracks from local storage (useful for removing mock data)
  Future<void> clearAllTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_tracks');
      Logger.log('All tracks cleared from local storage');
    } catch (e) {
      Logger.log('Error clearing tracks: $e');
    }
  }

  /// Get available genres from the database
  Future<List<String>> getAvailableGenres() async {
    if (!isSupabaseAvailable) {
      return ['All', 'Pop', 'Rock', 'Electronic', 'Jazz', 'Classical', 'Blues'];
    }

    try {
      final response = await _supabase
          .from('tracks')
          .select('genre');

      final genres = <String>['All'];

      for (final item in response) {
        final genre = item['genre']?.toString();
        if (genre != null && genre.isNotEmpty) {
          genres.add(genre);
        }
      }

      return genres;
    } catch (e) {
      Logger.log('Error getting genres: $e');
      return ['All', 'Pop', 'Rock', 'Electronic', 'Jazz', 'Classical', 'Blues'];
    }
  }

  // ===== Local Storage Fallback Methods =====

  /// Add a processing track to show in library during generation
  Future<String> addProcessingTrack(String prompt, String genre, String mood, String language, int duration) async {
    try {
      final processingId = 'processing_${DateTime.now().millisecondsSinceEpoch}';
      final processingTrack = AITrack(
        id: processingId,
        title: 'Generating: $prompt...',
        artist: 'AI Music Generator',
        genre: genre,
        mood: mood,
        duration: Duration(seconds: duration),
        audioUrl: '', // No audio URL during processing
        coverArtUrl: null,
        createdAt: DateTime.now(),
        isInstrumental: false,
        lyrics: null,
      );

      // Add processing status field
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      final trackJson = {
        'id': processingTrack.id,
        'title': processingTrack.title,
        'artist': processingTrack.artist,
        'genre': processingTrack.genre,
        'mood': processingTrack.mood,
        'duration': processingTrack.duration.inSeconds,
        'audioUrl': processingTrack.audioUrl,
        'coverArtUrl': processingTrack.coverArtUrl,
        'createdAt': processingTrack.createdAt.toIso8601String(),
        'isInstrumental': processingTrack.isInstrumental,
        'lyrics': processingTrack.lyrics,
        'isProcessing': true,
        'processingStatus': 'Initializing...',
        'isLocal': true,
      };

      tracksList.add(trackJson);
      await prefs.setString('local_tracks', jsonEncode(tracksList));

      Logger.log('Added processing track: $processingId');
      return processingId;
    } catch (e) {
      Logger.log('Error adding processing track: $e');
      return '';
    }
  }

  /// Update processing track status
  Future<void> updateProcessingStatus(String processingId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      for (int i = 0; i < tracksList.length; i++) {
        if (tracksList[i]['id'] == processingId) {
          tracksList[i]['processingStatus'] = status;
          break;
        }
      }

      await prefs.setString('local_tracks', jsonEncode(tracksList));
      Logger.log('Updated processing status for $processingId: $status');
    } catch (e) {
      Logger.log('Error updating processing status: $e');
    }
  }

  /// Convert processing track to completed track
  Future<void> completeProcessingTrack(String processingId, AITrack completedTrack) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      for (int i = 0; i < tracksList.length; i++) {
        if (tracksList[i]['id'] == processingId) {
          // Replace processing track with completed track
          tracksList[i] = {
            'id': completedTrack.id,
            'title': completedTrack.title,
            'artist': completedTrack.artist,
            'genre': completedTrack.genre,
            'mood': completedTrack.mood,
            'duration': completedTrack.duration.inSeconds,
            'audioUrl': completedTrack.audioUrl,
            'coverArtUrl': completedTrack.coverArtUrl,
            'createdAt': completedTrack.createdAt.toIso8601String(),
            'isInstrumental': completedTrack.isInstrumental,
            'lyrics': completedTrack.lyrics,
            'isProcessing': false,
            'processingCompleted': true,
            'isLocal': true,
          };
          break;
        }
      }

      await prefs.setString('local_tracks', jsonEncode(tracksList));
      Logger.log('Completed processing track: $processingId -> ${completedTrack.title}');
    } catch (e) {
      Logger.log('Error completing processing track: $e');
    }
  }

  /// Remove processing track (if failed)
  Future<void> removeProcessingTrack(String processingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      tracksList.removeWhere((track) => track['id'] == processingId);

      await prefs.setString('local_tracks', jsonEncode(tracksList));
      Logger.log('Removed processing track: $processingId');
    } catch (e) {
      Logger.log('Error removing processing track: $e');
    }
  }

  /// Save track to local SharedPreferences
  Future<bool> _saveTrackLocally(AITrack track) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      // Check for duplicates by ID or title+artist combination
      final isDuplicate = tracksList.any((existingTrack) =>
        existingTrack['id'] == track.id ||
        (existingTrack['title'] == track.title && existingTrack['artist'] == track.artist)
      );

      if (isDuplicate) {
        Logger.log('Track already exists, skipping save: ${track.title}');
        return false;
      }

      // Convert track to JSON
      final trackJson = {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'genre': track.genre,
        'mood': track.mood,
        'duration': track.duration.inSeconds,
        'audioUrl': track.audioUrl,
        'coverArtUrl': track.coverArtUrl,
        'createdAt': track.createdAt.toIso8601String(),
        'isInstrumental': track.isInstrumental,
        'lyrics': track.lyrics,
        'isLocal': true,
      };

      tracksList.add(trackJson);
      await prefs.setString('local_tracks', jsonEncode(tracksList));
      Logger.log('Track saved locally: ${track.title}');
      return true;
    } catch (e) {
      Logger.log('Error saving track locally: $e');
      return false;
    }
  }

  /// Get tracks from local SharedPreferences
  Future<List<AITrack>> _getLocalTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('local_tracks') ?? '[]';
      final List<dynamic> tracksList = jsonDecode(tracksJson);

      final tracks = tracksList.map((trackJson) {
        return AITrack(
          id: trackJson['id'],
          title: trackJson['title'],
          artist: trackJson['artist'],
          genre: trackJson['genre'],
          mood: trackJson['mood'],
          duration: Duration(seconds: trackJson['duration']),
          audioUrl: trackJson['audioUrl'] ?? '',
          coverArtUrl: trackJson['coverArtUrl'],
          createdAt: DateTime.parse(trackJson['createdAt']),
          isInstrumental: trackJson['isInstrumental'] ?? false,
          lyrics: trackJson['lyrics'],
          metadata: trackJson['metadata'],
          isProcessing: trackJson['isProcessing'] ?? false,
          processingStatus: trackJson['processingStatus'],
          processingCompleted: trackJson['processingCompleted'] ?? false,
        );
      }).toList();

      // If no local tracks, return mock data
      if (tracks.isEmpty) {
        return [];
      }

      Logger.log('Loaded ${tracks.length} tracks from local storage');
      return tracks;
    } catch (e) {
      Logger.log('Error loading local tracks: $e');
      return [];
    }
  }
}