import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';
import '../services/secure_storage_service.dart';
import '../services/webhook_service.dart';
import '../services/track_database_service.dart';
import '../models/ai_track.dart';
import '../models/generated_track.dart';

/// AI Music Generation Service using kie.ai Suno API
class AIMusicService {
  Dio? _dio;
  static const String _baseUrl = ApiConstants.kieAiBaseUrl;

  /// Get the initialized Dio instance
  Future<Dio> get _dioInstance async {
    if (_dio == null) {
      _dio = await _createDio();
    }
    return _dio!;
  }

  /// Create and configure Dio instance with stored API key
  Future<Dio> _createDio() async {
    // Try to get API key from secure storage first, then fall back to constants
    String? apiKey = await SecureStorageService.getKieAiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_kie_ai_api_key_here') {
      apiKey = ApiConstants.kieAiApiKey;
    }

    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5), // Music generation can take time
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Initialize interceptors
    _initializeDio(dio);

    return dio;
  }

  // Music generation parameters
  static const List<String> supportedGenres = [
    'pop', 'rock', 'electronic', 'classical', 'jazz', 'blues', 'country',
    'folk', 'r&b', 'hip_hop', 'dance', 'world', 'indie', 'ambient', 'experimental'
  ];

  // Arabic-specific genres (when Arabic mode is enabled)
  static const List<String> arabicGenres = [
    'arabic_traditional', 'arabic_pop', 'arabic_classical', 'maqam',
    'tarab', 'dabke', 'khaleeji', 'maghrebi', 'andalusi', 'sufi'
  ];

  static const List<String> supportedMoods = [
    'happy', 'sad', 'energetic', 'relaxing', 'dramatic', 'romantic',
    'uplifting', 'mysterious', 'dreamy', 'intense', 'playful', 'elegant'
  ];

  static const List<String> supportedLanguages = [
    'english', 'arabic', 'spanish', 'french', 'german', 'chinese',
    'japanese', 'korean', 'hindi', 'portuguese', 'russian', 'italian'
  ];

  AIMusicService() {
    // Initialize Dio will be called lazily when needed
  }

  /// Initialize Dio with interceptors (called after Dio is created)
  void _initializeDio(Dio dio) {
    // Add logging for development
    if (!AppConstants.isProduction) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (Object object) => Logger.log(object.toString()),
        requestHeader: false,
        responseHeader: false,
      ));
    }

    // Add error handling
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        Logger.log('AI Music API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Generate AI music using Suno API
  Future<GeneratedTrack> generateMusic({
    required String prompt,
    String? genre,
    String? mood,
    String? style,
    String? lyrics,
    String? language = 'english',
    bool includeLyrics = false,
    int duration = 120,
    bool instrumental = false,
    String? vocalGender,
    double temperature = 0.7,
    String? model = 'V5',
    String? personaId,
    double? styleWeight,
    double? weirdnessConstraint,
    double? audioWeight,
    String? negativeTags,
    Function(String taskId)? onTaskIdReceived,
    Function(AITrack completedTrack)? onTrackCompleted,
  }) async {
    try {
      // Format the prompt for music generation (not including the description as lyrics)
      final formattedPrompt = _formatMusicPromptForKieAi(genre, mood, style, lyrics, duration, includeLyrics);

      final requestData = {
        'prompt': formattedPrompt,
        'instrumental': instrumental,
        'model': model ?? 'V5',
        'customMode': true, // Enable advanced parameters for better control
        'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/music',
      };

      // Add style and title for better generation quality
      if (style != null && style.isNotEmpty) {
        requestData['style'] = style;
      } else if (genre != null && genre.isNotEmpty) {
        requestData['style'] = genre;
      } else if (mood != null && mood.isNotEmpty) {
        requestData['style'] = mood;
      }

      // Use the prompt (description) as the track title
      requestData['title'] = _generateTrackTitle(prompt, genre, mood);

      // Add v5-specific advanced parameters if provided
      if (personaId != null && personaId.isNotEmpty) {
        requestData['personaId'] = personaId;
      }
      if (styleWeight != null) {
        requestData['styleWeight'] = styleWeight.clamp(0.0, 1.0);
      }
      if (weirdnessConstraint != null) {
        requestData['weirdnessConstraint'] = weirdnessConstraint.clamp(0.0, 1.0);
      }
      if (audioWeight != null) {
        requestData['audioWeight'] = audioWeight.clamp(0.0, 1.0);
      }
      if (negativeTags != null && negativeTags.isNotEmpty) {
        requestData['negativeTags'] = negativeTags;
      }
      if (vocalGender != null && vocalGender.isNotEmpty) {
        // Ensure correct format for kie.ai API
        requestData['vocalGender'] = vocalGender.toLowerCase() == 'male' ? 'm' :
                                   vocalGender.toLowerCase() == 'female' ? 'f' : vocalGender;
      }

      // Add temperature parameter if provided (creativity level)
      if (temperature != 0.7) {
        // Map temperature to weirdnessConstraint if not already set
        if (weirdnessConstraint == null) {
          requestData['weirdnessConstraint'] = temperature.clamp(0.0, 1.0);
        }
      }

      Logger.log('🎵 Sending music generation request:');
      Logger.log('  Formatted Prompt: $formattedPrompt');
      Logger.log('  Model: ${requestData['model']}');
      Logger.log('  Instrumental: ${requestData['instrumental']}');
      Logger.log('  Custom Mode: ${requestData['customMode']}');

      // Check if API key is configured
      final apiKey = await SecureStorageService.getKieAiKey();
      if (apiKey == null || apiKey.isEmpty || !SecureStorageService.isValidKieAiKey(apiKey)) {
        throw Exception('kie.ai API key not configured. Please add your API key in settings.');
      }

      final dio = await _dioInstance;
      final response = await dio.post(
        ApiConstants.musicGeneration,
        data: requestData,
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        Logger.log('API response received: $data');

        // Check if response contains an error even with HTTP 200
        Logger.log('DEBUG: Checking for error in response: ${data is Map ? "Map" : "Not Map"}, hasCode: ${data is Map && data.containsKey('code')}, code: ${data is Map ? data['code'] : 'N/A'}');

        if (data is Map && data.containsKey('code') && data['code'] != 200) {
          final errorCode = data['code'] ?? 'unknown';
          final errorMessage = data['msg'] ?? 'Unknown error occurred';
          Logger.log('API returned error: $errorCode - $errorMessage');
          throw Exception('kie.ai API error ($errorCode): $errorMessage');
        }

        // Check if response contains a taskId (kie.ai async response)
        if (data is Map && data.containsKey('data') && data['data'] is Map && data['data']['taskId'] != null) {
          final taskId = data['data']['taskId'];
          Logger.log('✅ Received taskId: $taskId - Music generation submitted successfully');

          // Create processing track and save to Supabase immediately
          final trackTitle = _generateTrackTitle(prompt, genre, mood);
          final processingTrack = AITrack(
            id: taskId,
            title: 'Generating: ${trackTitle.substring(0, trackTitle.length.clamp(0, 30))}...',
            artist: 'AI Music Generator',
            genre: genre ?? 'AI Music',
            mood: mood ?? 'Generated',
            duration: Duration(seconds: duration),
            audioUrl: '', // Will be updated by webhook
            coverArtUrl: null,
            createdAt: DateTime.now(),
            isInstrumental: instrumental,
            lyrics: lyrics,
            isProcessing: true,
            processingStatus: 'Submitted to kie.ai - waiting for webhook...',
            processingCompleted: false,
            metadata: {
              'taskId': taskId,
              'originalDescription': prompt, // User's description for track name
              'musicPrompt': formattedPrompt, // Actual prompt sent to kie.ai
              'requestedGenre': genre,
              'requestedMood': mood,
              'webhookExpected': true,
            },
          );

          // Save processing track to database
          try {
            await TrackDatabaseService().saveTrack(processingTrack);
            Logger.log('✅ Processing track saved to database with taskId: $taskId');
          } catch (e) {
            Logger.log('❌ Failed to save processing track: $e');
          }

          // Notify UI of the processing track
          if (onTaskIdReceived != null) {
            onTaskIdReceived(taskId);
          }

          if (onTrackCompleted != null) {
            onTrackCompleted(processingTrack);
          }

          // Start polling for status updates as webhook fallback
          _startPollingForTrackCompletion(taskId, onTrackCompleted);

          // Return a mock generated track for UI compatibility
          // Real track will be updated by webhook or polling
          return GeneratedTrack(
            id: taskId,
            title: processingTrack.title,
            artist: processingTrack.artist,
            genre: processingTrack.genre,
            mood: processingTrack.mood,
            audioUrl: '',
            coverImageUrl: '',
            duration: duration,
            createdAt: DateTime.now(),
            metadata: processingTrack.metadata ?? {},
          );
        }

        // Try to parse as complete track
        try {
          return GeneratedTrack.fromJson(Map<String, dynamic>.from(data));
        } catch (e) {
          Logger.log('Failed to parse track response: $e');
          throw Exception('Failed to parse kie.ai API response: $e');
        }
      } else {
        // API call failed with non-200 status
        final errorMessage = response.data?['msg'] ?? 'API call failed';
        Logger.log('API call failed: ${response.statusCode} - $errorMessage');
        throw Exception('kie.ai API error (${response.statusCode}): $errorMessage');
      }
    } on DioException catch (e) {
      Logger.log('Error generating music: $e');
      throw Exception('Network error calling kie.ai API: ${e.message}');
    } catch (e) {
      Logger.log('Unexpected error generating music: $e');
      throw Exception('Unexpected error: $e');
    }
  }


  /// Format prompt according to kie.ai best practices with duration hints
  String _formatPromptForKieAi(String prompt, String? genre, String? mood, String? style, String? lyrics, int duration) {
    var formattedPrompt = prompt.trim();

    // Add aggressive duration hints since API has no direct duration parameter
    String durationHint = '';
    String durationSuffix = '';

    if (duration <= 30) {
      durationHint = 'extremely short 30-second clip';
      durationSuffix = ', keep it under 30 seconds, brief and concise';
    } else if (duration <= 45) {
      durationHint = 'very short 45-second snippet';
      durationSuffix = ', maximum 45 seconds duration';
    } else if (duration <= 60) {
      durationHint = 'one minute track';
      durationSuffix = ', exactly 60 seconds long';
    } else if (duration <= 90) {
      durationHint = 'short 90-second piece';
      durationSuffix = ', keep under 90 seconds';
    } else if (duration <= 120) {
      durationHint = 'two minute song';
      durationSuffix = ', around 120 seconds duration';
    } else {
      durationHint = 'full length track';
      durationSuffix = '';
    }

    // Include multiple duration hints in prompt for better compliance
    if (duration <= 120) {
      formattedPrompt = '$durationHint $formattedPrompt$durationSuffix';
    }

    // Add style and mood context if provided
    if (mood != null && mood.isNotEmpty) {
      formattedPrompt = '$mood $formattedPrompt';
    }

    if (genre != null && genre.isNotEmpty) {
      formattedPrompt = '$genre $formattedPrompt';
    }

    if (style != null && style.isNotEmpty && style != 'modern') {
      formattedPrompt = '$formattedPrompt with $style style';
    }

    // Add custom lyrics if provided
    if (lyrics != null && lyrics.isNotEmpty) {
      formattedPrompt = '$formattedPrompt. Lyrics: $lyrics';
    }

    return formattedPrompt;
  }

  /// Generate a track title from the user's description
  String _generateTrackTitle(String description, String? genre, String? mood) {
    // Use the description directly as the title (this is what user expects)
    var title = description.trim();

    // Add genre/mood context if description is too generic
    if (title.length < 10 && genre != null && genre.isNotEmpty) {
      title = '$genre $title';
    }

    if (title.length < 15 && mood != null && mood.isNotEmpty) {
      title = '$mood $title';
    }

    // Limit to 80 characters as per kie.ai requirements
    if (title.length > 80) {
      title = title.substring(0, 77) + '...';
    }

    return title.isNotEmpty ? title : 'AI Generated Track';
  }

  /// Format music generation prompt (separate from user description)
  String _formatMusicPromptForKieAi(String? genre, String? mood, String? style, String? lyrics, int duration, bool includeLyrics) {
    var musicPrompt = '';

    // Build music generation prompt without user description
    // Add genre as the base
    if (genre != null && genre.isNotEmpty) {
      musicPrompt = genre;
    }

    // Add mood context
    if (mood != null && mood.isNotEmpty) {
      musicPrompt = musicPrompt.isEmpty ? mood : '$mood $musicPrompt';
    }

    // Add style specification
    if (style != null && style.isNotEmpty && style != 'modern') {
      musicPrompt = musicPrompt.isEmpty ? style : '$musicPrompt with $style style';
    }

    // If no specific parameters, use generic music prompt
    if (musicPrompt.isEmpty) {
      musicPrompt = 'music track';
    }

    // Add aggressive duration hints
    String durationHint = '';
    String durationSuffix = '';

    if (duration <= 30) {
      durationHint = 'extremely short 30-second clip';
      durationSuffix = ', keep it under 30 seconds, brief and concise';
    } else if (duration <= 45) {
      durationHint = 'very short 45-second snippet';
      durationSuffix = ', maximum 45 seconds duration';
    } else if (duration <= 60) {
      durationHint = 'one minute track';
      durationSuffix = ', exactly 60 seconds long';
    } else if (duration <= 90) {
      durationHint = 'short 90-second piece';
      durationSuffix = ', keep under 90 seconds';
    } else if (duration <= 120) {
      durationHint = 'two minute song';
      durationSuffix = ', around 120 seconds duration';
    }

    // Include duration hint in prompt
    if (duration <= 120) {
      musicPrompt = '$durationHint $musicPrompt$durationSuffix';
    }

    // Add custom lyrics ONLY if user explicitly wants them and provided them
    if (includeLyrics && lyrics != null && lyrics.isNotEmpty) {
      musicPrompt = '$musicPrompt. Lyrics: $lyrics';
    }

    return musicPrompt;
  }

  /// Poll kie.ai for track completion status as webhook fallback
  Future<void> _startPollingForTrackCompletion(String taskId, Function(AITrack)? onTrackCompleted) async {
    Logger.log('🔄 Starting polling fallback for taskId: $taskId');

    int attempts = 0;
    const maxAttempts = 20; // 10 minutes max (30s intervals)
    const pollInterval = Duration(seconds: 30);

    while (attempts < maxAttempts) {
      await Future.delayed(pollInterval);
      attempts++;

      try {
        Logger.log('🔍 Polling attempt $attempts for taskId: $taskId');

        final dio = await _dioInstance;
        final response = await dio.get(
          '${ApiConstants.musicStatus}/$taskId',
          options: Options(responseType: ResponseType.json),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          Logger.log('📋 Status response: $data');

          // Check if generation is complete
          if (data is Map && data.containsKey('data')) {
            final trackDataList = data['data'] as List?;

            if (trackDataList != null && trackDataList.isNotEmpty) {
              Logger.log('🎵 Polling found ${trackDataList.length} tracks for taskId: $taskId');

              // Log all tracks for analysis
              for (int i = 0; i < trackDataList.length; i++) {
                final track = trackDataList[i] as Map<String, dynamic>;
                Logger.log('   Track ${i + 1}: ${track['title']} - Duration: ${track['duration']}s');
              }

              // Get the requested duration from stored track metadata
              int requestedDuration = 120; // Default fallback
              try {
                // Try to get the original track to find requested duration
                final tracks = await TrackDatabaseService().getAllTracks();
                final originalTrack = tracks.firstWhere((t) => t.id == taskId);
                requestedDuration = originalTrack.duration.inSeconds;
              } catch (e) {
                Logger.log('⚠️ Could not find original track duration, using default: $e');
              }

              // Save all tracks as alternatives, then select the best one by default
              await _saveAllTrackAlternatives(taskId, trackDataList, requestedDuration);

              // Select track closest to requested duration as the primary
              final trackData = _selectBestTrack(trackDataList, requestedDuration);
              final audioUrl = trackData['audio_url'] ?? trackData['audioUrl'];

              if (audioUrl != null && audioUrl.toString().isNotEmpty) {
                Logger.log('✅ Selected track completed via polling: $audioUrl');
                Logger.log('📏 Selected track duration: ${trackData['duration']}s');

                // Update the track in database
                await _updateTrackFromPolling(taskId, trackData);

                // Notify callback if provided
                if (onTrackCompleted != null) {
                  final completedTrack = await _createCompletedTrack(taskId, trackData);
                  onTrackCompleted(completedTrack);
                }

                Logger.log('🎵 Polling completed successfully for taskId: $taskId');
                return;
              }
            }
          }
        }

        Logger.log('⏳ Track still processing... (attempt $attempts/$maxAttempts)');

      } catch (e) {
        Logger.log('❌ Polling error (attempt $attempts): $e');

        // Continue polling unless it's the last attempt
        if (attempts >= maxAttempts) {
          Logger.log('🚫 Polling failed after $maxAttempts attempts for taskId: $taskId');
          break;
        }
      }
    }

    Logger.log('⏰ Polling timeout for taskId: $taskId after $attempts attempts');
  }

  /// Update track from polling data
  Future<void> _updateTrackFromPolling(String taskId, Map<String, dynamic> trackData) async {
    try {
      final audioUrl = trackData['audio_url'] ?? trackData['audioUrl'] ?? '';
      final imageUrl = trackData['image_url'] ?? trackData['imageUrl'] ?? '';

      final updateData = {
        'audio_url': audioUrl,
        'cover_art_url': imageUrl,
        'title': trackData['title'] ?? 'AI Generated Track',
        'duration_seconds': (trackData['duration'] is num) ? trackData['duration'].toInt() : 120,
        'is_processing': false,
        'processing_completed': true,
        'processing_status': 'Completed via polling',
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': {
          'sunoId': trackData['id'] ?? '',
          'prompt': trackData['prompt'] ?? '',
          'model_name': trackData['model_name'] ?? 'V5',
          'tags': trackData['tags'] ?? '',
          'streamAudioUrl': trackData['stream_audio_url'] ?? trackData['streamAudioUrl'] ?? '',
          'completedViaPolling': true,
          'completedAt': DateTime.now().toIso8601String(),
          'originalTaskId': taskId,
        },
      };

      // Use actual track title from kie.ai or fallback to generated one
      final actualTitle = trackData['title'] ?? updateData['title'] ?? 'AI Generated Track';

      // Create updated track object and save it
      final updatedTrack = AITrack(
        id: taskId,
        title: actualTitle,
        artist: 'AI Artist',
        genre: 'AI Music',
        mood: 'Generated',
        duration: Duration(seconds: updateData['duration_seconds'] as int),
        audioUrl: updateData['audio_url'] as String,
        coverArtUrl: updateData['cover_art_url'] as String?,
        createdAt: DateTime.now(),
        isInstrumental: false,
        isProcessing: updateData['is_processing'] as bool,
        processingStatus: updateData['processing_status'] as String,
        processingCompleted: updateData['processing_completed'] as bool,
        metadata: updateData['metadata'] as Map<String, dynamic>,
      );

      await TrackDatabaseService().saveTrack(updatedTrack);
      Logger.log('✅ Track updated via polling: $taskId');

    } catch (e) {
      Logger.log('❌ Error updating track via polling: $e');
    }
  }

  /// Create AITrack from completed data
  Future<AITrack> _createCompletedTrack(String taskId, Map<String, dynamic> trackData) async {
    return AITrack(
      id: taskId,
      title: trackData['title'] ?? 'AI Generated Track',
      artist: 'AI Artist',
      genre: 'AI Music',
      mood: 'Generated',
      duration: Duration(seconds: (trackData['duration'] is num) ? trackData['duration'].toInt() : 120),
      audioUrl: trackData['audio_url'] ?? trackData['audioUrl'] ?? '',
      coverArtUrl: trackData['image_url'] ?? trackData['imageUrl'],
      createdAt: DateTime.now(),
      isInstrumental: false,
      isProcessing: false,
      processingStatus: 'Completed via polling',
      processingCompleted: true,
      metadata: {
        'sunoId': trackData['id'] ?? '',
        'originalTaskId': taskId,
        'completedViaPolling': true,
      },
    );
  }

  /// Select the best track from multiple options based on requested duration
  Map<String, dynamic> _selectBestTrack(List trackDataList, int requestedDuration) {
    if (trackDataList.isEmpty) {
      throw Exception('No tracks available to select from');
    }

    if (trackDataList.length == 1) {
      return trackDataList[0] as Map<String, dynamic>;
    }

    // Find track with duration closest to requested duration
    Map<String, dynamic> bestTrack = trackDataList[0] as Map<String, dynamic>;
    double bestDifference = double.infinity;

    for (int i = 0; i < trackDataList.length; i++) {
      final track = trackDataList[i] as Map<String, dynamic>;
      final trackDuration = (track['duration'] as num?)?.toDouble() ?? 120.0;
      final difference = (trackDuration - requestedDuration).abs();

      Logger.log('   Evaluating Track ${i + 1}: ${track['title']} - Duration: ${trackDuration}s (diff: ${difference.toStringAsFixed(1)}s)');

      if (difference < bestDifference) {
        bestDifference = difference;
        bestTrack = track;
      }
    }

    final selectedDuration = (bestTrack['duration'] as num?)?.toDouble() ?? 120.0;
    Logger.log('🎯 Selected best track: ${bestTrack['title']} - Duration: ${selectedDuration}s (closest to ${requestedDuration}s)');

    return bestTrack;
  }

  /// Save all track alternatives to allow user choice
  Future<void> _saveAllTrackAlternatives(String baseTaskId, List trackDataList, int requestedDuration) async {
    try {
      for (int i = 0; i < trackDataList.length; i++) {
        final track = trackDataList[i] as Map<String, dynamic>;
        // Determine which track should be the default (closest to requested duration)
        final trackDuration = (track['duration'] as num?)?.toDouble() ?? 120.0;
        final isClosest = _isClosestToRequestedDuration(track, trackDataList, requestedDuration);
        final isDefault = (i == 0) || isClosest; // First track OR closest to duration

        // Create unique ID for each alternative
        final trackId = isDefault ? baseTaskId : '${baseTaskId}_alt_${i + 1}';

        final audioUrl = track['audio_url'] ?? track['audioUrl'] ?? '';
        final imageUrl = track['image_url'] ?? track['imageUrl'] ?? '';
        final actualTitle = track['title'] ?? 'AI Generated Track ${i + 1}';

        final alternativeTrack = AITrack(
          id: trackId,
          title: actualTitle,
          artist: 'AI Artist',
          genre: 'AI Music',
          mood: 'Generated',
          duration: Duration(seconds: (track['duration'] is num) ? track['duration'].toInt() : 120),
          audioUrl: audioUrl,
          coverArtUrl: imageUrl,
          createdAt: DateTime.now(),
          isInstrumental: false,
          isProcessing: false,
          processingStatus: 'Completed - Alternative ${i + 1}',
          processingCompleted: true,
          metadata: {
            'sunoId': track['id'] ?? '',
            'prompt': track['prompt'] ?? '',
            'model_name': track['model_name'] ?? 'V5',
            'tags': track['tags'] ?? '',
            'streamAudioUrl': track['stream_audio_url'] ?? track['streamAudioUrl'] ?? '',
            'completedViaPolling': true,
            'completedAt': DateTime.now().toIso8601String(),
            'originalTaskId': baseTaskId,
            'alternativeIndex': i + 1,
            'isDefault': isDefault,
            'requestedDuration': requestedDuration,
            'actualDuration': track['duration'],
            'durationDifference': ((track['duration'] as num?)?.toDouble() ?? 120.0) - requestedDuration,
          },
        );

        await TrackDatabaseService().saveTrack(alternativeTrack);
        Logger.log('💾 Saved alternative track ${i + 1}: $actualTitle (${track['duration']}s)');
      }
    } catch (e) {
      Logger.log('❌ Error saving track alternatives: $e');
    }
  }

  /// Check if this track is closest to the requested duration
  bool _isClosestToRequestedDuration(Map<String, dynamic> track, List trackDataList, int requestedDuration) {
    final trackDuration = (track['duration'] as num?)?.toDouble() ?? 120.0;
    final trackDifference = (trackDuration - requestedDuration).abs();

    for (final otherTrackData in trackDataList) {
      final otherTrack = otherTrackData as Map<String, dynamic>;
      final otherDuration = (otherTrack['duration'] as num?)?.toDouble() ?? 120.0;
      final otherDifference = (otherDuration - requestedDuration).abs();

      if (otherDifference < trackDifference && otherTrack != track) {
        return false;
      }
    }
    return true;
  }

}

/// Generated track data model
class GeneratedTrack {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String mood;
  final String audioUrl;
  final String coverImageUrl;
  final int duration;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const GeneratedTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.mood,
    required this.audioUrl,
    required this.coverImageUrl,
    required this.duration,
    required this.createdAt,
    this.metadata = const {},
  });

  factory GeneratedTrack.fromJson(Map<String, dynamic> json) {
    return GeneratedTrack(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Generated Track',
      artist: json['artist'] ?? 'AI Artist',
      genre: json['genre'] ?? 'pop',
      mood: json['mood'] ?? 'happy',
      audioUrl: json['audio_url'] ?? '',
      coverImageUrl: json['cover_image_url'] ?? '',
      duration: json['duration'] ?? 120,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'genre': genre,
      'mood': mood,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Extended track model for continuation
class ExtendedTrack {
  final String extendedAudioUrl;
  final int extendedDuration;
  final DateTime extendedAt;

  const ExtendedTrack({
    required this.extendedAudioUrl,
    required this.extendedDuration,
    required this.extendedAt,
  });

  factory ExtendedTrack.fromJson(Map<String, dynamic> json) {
    return ExtendedTrack(
      extendedAudioUrl: json['extended_audio_url'] ?? '',
      extendedDuration: json['extended_duration'] ?? 0,
      extendedAt: DateTime.parse(json['extended_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Audio stems response model
class AudioStemsResponse {
  final String vocalsUrl;
  final String drumsUrl;
  final String bassUrl;
  final String otherUrl;

  const AudioStemsResponse({
    required this.vocalsUrl,
    required this.drumsUrl,
    required this.bassUrl,
    required this.otherUrl,
  });

  factory AudioStemsResponse.fromJson(Map<String, dynamic> json) {
    return AudioStemsResponse(
      vocalsUrl: json['vocals_url'] ?? '',
      drumsUrl: json['drums_url'] ?? '',
      bassUrl: json['bass_url'] ?? '',
      otherUrl: json['other_url'] ?? '',
    );
  }
}

/// Model capabilities information
class ModelCapabilities {
  final List<String> availableModels;
  final Map<String, dynamic> modelLimits;
  final List<String> supportedGenres;
  final List<String> supportedMoods;
  final List<String> supportedLanguages;
  final Map<String, dynamic> features;

  const ModelCapabilities({
    required this.availableModels,
    required this.modelLimits,
    required this.supportedGenres,
    required this.supportedMoods,
    required this.supportedLanguages,
    required this.features,
  });

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) {
    return ModelCapabilities(
      availableModels: List<String>.from(json['available_models'] ?? []),
      modelLimits: Map<String, dynamic>.from(json['model_limits'] ?? {}),
      supportedGenres: List<String>.from(json['supported_genres'] ?? []),
      supportedMoods: List<String>.from(json['supported_moods'] ?? []),
      supportedLanguages: List<String>.from(json['supported_languages'] ?? []),
      features: Map<String, dynamic>.from(json['features'] ?? {}),
    );
  }

  static ModelCapabilities getDefault() {
    return const ModelCapabilities(
      availableModels: ['suno-v5', 'suno-v4'],
      modelLimits: {
        'max_duration': 600,
        'max_lyrics_length': 5000,
      },
      supportedGenres: ['pop', 'rock', 'electronic', 'classical'],
      supportedMoods: ['happy', 'sad', 'energetic', 'relaxing'],
      supportedLanguages: ['english', 'arabic', 'spanish'],
      features: {
        'lyrics_generation': true,
        'stem_separation': true,
        'cover_art_generation': true,
        'track_extension': true,
      },
    );
  }
}