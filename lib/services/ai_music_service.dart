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
      // Format the prompt according to kie.ai best practices
      final formattedPrompt = _formatPromptForKieAi(prompt, genre, mood, style, lyrics);

      final requestData = {
        'prompt': formattedPrompt,
        'instrumental': instrumental,
        'model': model ?? 'V5',
        'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/music', // Webhook for real-time updates
      };

      // Add optional parameters
      if (includeLyrics && lyrics != null && lyrics.isNotEmpty) {
        requestData['customMode'] = true;
        requestData['style'] = style ?? 'modern';
        requestData['title'] = _generateTitle(prompt, genre);
      } else {
        requestData['customMode'] = false;
      }

      // Add v5-specific parameters if provided
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
        requestData['vocalGender'] = vocalGender;
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
          final processingTrack = AITrack(
            id: taskId,
            title: 'Generating: ${prompt.substring(0, prompt.length.clamp(0, 30))}...',
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
              'originalPrompt': prompt,
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

          // Return a mock generated track for UI compatibility
          // Real track will be updated by webhook
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


  /// Format prompt according to kie.ai best practices
  String _formatPromptForKieAi(String prompt, String? genre, String? mood, String? style, String? lyrics) {
    var formattedPrompt = prompt.trim();

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

  /// Generate a title from prompt and genre
  String _generateTitle(String prompt, String? genre) {
    // Take first 3-4 words from prompt and capitalize
    final words = prompt.split(' ').take(4);
    var title = words.map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');

    // Limit to 80 characters as per kie.ai requirements
    if (title.length > 80) {
      title = title.substring(0, 77) + '...';
    }

    return title.isNotEmpty ? title : 'AI Generated Track';
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