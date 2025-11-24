import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// kie.ai API service for AI music generation, images, and LLM
class KieAiService {
  late final Dio _dio;
  static const String _baseUrl = 'https://api.kie.ai/v1';

  KieAiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.kieAiApiKey}',
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor for development
    if (!AppConstants.isProduction) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: Logger.log,
      ));
    }
  }

  /// Generate music using Suno API (kie.ai)
  Future<SunoMusicResponse> generateMusic({
    required String prompt,
    required String genre,
    required String mood,
    bool includeLyrics = false,
    String? customLyrics,
    int duration = 120, // seconds
  }) async {
    try {
      final response = await _dio.post('/suno/generate', data: {
        'prompt': prompt,
        'genre': genre,
        'mood': mood,
        'include_lyrics': includeLyrics,
        'lyrics': customLyrics,
        'duration': duration,
        'model': 'suno-v3', // Latest Suno model
      });

      if (response.statusCode == 200) {
        return SunoMusicResponse.fromJson(response.data);
      } else {
        throw ApiException('Failed to generate music: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      Logger.log('Error generating music: $e');
      throw ApiException('Music generation failed: ${e.message}');
    }
  }

  /// Generate AI avatar using 4o Image API
  Future<String> generateAvatar({
    required String description,
    String style = 'realistic',
    String aspectRatio = '1:1',
  }) async {
    try {
      final response = await _dio.post('/image/generate', data: {
        'prompt': description,
        'model': '4o-image',
        'style': style,
        'aspect_ratio': aspectRatio,
        'quality': 'high',
        'size': '1024x1024',
      });

      if (response.statusCode == 200) {
        return response.data['data'][0]['url'];
      } else {
        throw ApiException('Failed to generate avatar: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      Logger.log('Error generating avatar: $e');
      throw ApiException('Avatar generation failed: ${e.message}');
    }
  }

  /// Generate lyrics using LLM
  Future<String> generateLyrics({
    required String theme,
    required String genre,
    String? artist,
    int length = 200, // words
  }) async {
    try {
      final response = await _dio.post('/llm/generate', data: {
        'prompt': '''
        Generate lyrics for a $genre song with the theme: "$theme"
        ${artist != null ? 'in the style of $artist' : ''}

        Requirements:
        - Length: around $length words
        - Include verse, chorus, bridge structure
        - Make it emotional and engaging
        - Suitable for radio play
        ''',
        'model': 'gpt-4-turbo',
        'max_tokens': 500,
        'temperature': 0.8,
      });

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      } else {
        throw ApiException('Failed to generate lyrics: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      Logger.log('Error generating lyrics: $e');
      throw ApiException('Lyrics generation failed: ${e.message}');
    }
  }

  /// Extend existing audio track
  Future<String> extendTrack({
    required String audioUrl,
    required int extendDuration, // seconds
  }) async {
    try {
      final response = await _dio.post('/suno/extend', data: {
        'audio_url': audioUrl,
        'extend_duration': extendDuration,
        'continuation_style': 'seamless',
      });

      if (response.statusCode == 200) {
        return response.data['extended_audio_url'];
      } else {
        throw ApiException('Failed to extend track: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      Logger.log('Error extending track: $e');
      throw ApiException('Track extension failed: ${e.message}');
    }
  }

  /// Separate audio stems (vocals, instruments, etc.)
  Future<AudioStemsResponse> separateStems({
    required String audioUrl,
  }) async {
    try {
      final response = await _dio.post('/audio/separate-stems', data: {
        'audio_url': audioUrl,
        'output_format': 'mp3',
        'quality': 'high',
      });

      if (response.statusCode == 200) {
        return AudioStemsResponse.fromJson(response.data);
      } else {
        throw ApiException('Failed to separate stems: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      Logger.log('Error separating stems: $e');
      throw ApiException('Stem separation failed: ${e.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}

// Response models
class SunoMusicResponse {
  final String audioUrl;
  final String title;
  final String artist;
  final int duration;
  final String coverImageUrl;

  SunoMusicResponse({
    required this.audioUrl,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverImageUrl,
  });

  factory SunoMusicResponse.fromJson(Map<String, dynamic> json) {
    return SunoMusicResponse(
      audioUrl: json['audio_url'] ?? '',
      title: json['title'] ?? 'Generated Track',
      artist: json['artist'] ?? 'AI Artist',
      duration: json['duration'] ?? 120,
      coverImageUrl: json['cover_image_url'] ?? '',
    );
  }
}

class AudioStemsResponse {
  final String vocalsUrl;
  final String drumsUrl;
  final String bassUrl;
  final String otherUrl;

  AudioStemsResponse({
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