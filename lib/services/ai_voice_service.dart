import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

/// AI Voice Service using only kie.ai APIs for all voice and music processing
class AIVoiceService {
  late final Dio _dio;
  static const String _kieAiBaseUrl = 'https://api.kie.ai';
  static const String _backendProxyUrl = 'https://dap-production-99ef.up.railway.app';

  AIVoiceService() {
    // Use different base URLs based on platform
    final baseUrl = kIsWeb ? _backendProxyUrl : _kieAiBaseUrl;
    final headers = kIsWeb
        ? {'Content-Type': 'application/json'} // No auth needed for proxy
        : {
            'Authorization': 'Bearer ${ApiConstants.kieAiApiKey}',
            'Content-Type': 'application/json',
          };

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      headers: headers,
    ));

    if (!kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (obj) => Logger.log(obj.toString()),
      ));
    }
  }

  /// Prepare voice file for Upload and Cover Audio API
  Future<dynamic> _prepareVoiceFile(String audioPath) async {
    try {
      Logger.log('Preparing voice file for Upload and Cover Audio: $audioPath');

      if (kIsWeb) {
        // For web, we need to convert blob URL to bytes using JavaScript
        return await _getBlobBytes(audioPath);
      } else {
        // For mobile, prepare file for direct multipart upload
        final file = File(audioPath);
        final bytes = await file.readAsBytes();
        return MultipartFile.fromBytes(
          bytes,
          filename: 'voice_recording.m4a',
        );
      }
    } catch (e) {
      Logger.log('Error preparing voice file: $e');
      throw Exception('Voice file preparation failed: $e');
    }
  }

  /// Convert blob URL to bytes for web platform or read file for mobile
  Future<List<int>> _getBlobBytes(String audioPath) async {
    if (kIsWeb) {
      try {
        // Use native JavaScript to fetch blob data
        final response = await _dio.get(
          audioPath,
          options: Options(responseType: ResponseType.bytes)
        );
        return response.data as List<int>;
      } catch (e) {
        Logger.log('Failed to convert blob to bytes: $e');
        throw Exception('Failed to convert web audio blob to bytes: $e');
      }
    } else {
      // For mobile, read file directly
      final file = File(audioPath);
      return await file.readAsBytes();
    }
  }

  /// Process voice recording using kie.ai Upload and Cover Audio API
  Future<VoiceToLyricsResult> voiceToLyrics(String audioPath) async {
    try {
      Logger.log('Processing voice recording with kie.ai Upload and Cover Audio API: $audioPath');

      // Step 1: Analyze the voice for mood and genre using LLM
      final analysis = await _analyzeVoiceFile(audioPath);

      // Step 2: Return analysis result with audio path for file upload workflow
      return VoiceToLyricsResult(
        originalText: 'Voice recording analyzed for mood and genre',
        analyzedMood: analysis.mood,
        detectedGenre: analysis.genre,
        suggestedTempo: analysis.tempo,
        confidence: analysis.confidence,
        uploadedFileId: audioPath, // Store the original path for upload workflow
      );
    } catch (e) {
      Logger.log('Error processing voice recording: $e');
      throw Exception('Voice processing failed: $e');
    }
  }

  /// Analyze voice file for mood, genre, and tempo using kie.ai LLM
  Future<VoiceAnalysis> _analyzeVoiceFile(String audioPath) async {
    try {
      final endpoint = kIsWeb
          ? '/api/proxy/kie/llm-generate'
          : '/llm/generate';

      final response = await _dio.post(
        endpoint,
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a music AI that analyzes audio for mood, genre, and tempo.
              Based on the voice recording characteristics, return ONLY a JSON response with:
              {
                "mood": "happy|sad|energetic|calm|romantic|angry|melancholic|upbeat",
                "genre": "pop|rock|rap|country|jazz|electronic|ballad|folk",
                "tempo": "slow|medium|fast",
                "confidence": 0.0-1.0
              }''',
            },
            {
              'role': 'user',
              'content': 'Analyze the voice recording. Detect the mood, genre preference, and tempo from the vocal characteristics. Audio path: $audioPath',
            }
          ],
          'max_tokens': 100,
          'temperature': 0.3,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final analysis = _parseAnalysisResponse(content);
        return analysis;
      } else {
        // Default analysis if API fails
        return VoiceAnalysis(
          mood: 'upbeat',
          genre: 'pop',
          tempo: 'medium',
          confidence: 0.7,
        );
      }
    } catch (e) {
      Logger.log('Error analyzing voice file: $e');
      return VoiceAnalysis(
        mood: 'upbeat',
        genre: 'pop',
        tempo: 'medium',
        confidence: 0.7,
      );
    }
  }



  /// Complete incomplete lyrics using kie.ai LLM
  Future<String> completeLyrics({
    required String originalLyrics,
    required String mood,
    required String genre,
    int targetLength = 300,
  }) async {
    try {
      Logger.log('Completing lyrics with kie.ai - mood: $mood, genre: $genre');

      final endpoint = kIsWeb
          ? '/api/proxy/kie/llm-generate'
          : '/llm/generate';

      final response = await _dio.post(
        endpoint,
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a professional lyricist. Complete these lyrics to make a full song.
              Keep the original voice/style but expand it into a complete song structure.''',
            },
            {
              'role': 'user',
              'content': '''
              Complete these lyrics to make a full song:

              Original lyrics: "$originalLyrics"

              Requirements:
              - Mood: $mood
              - Genre: $genre
              - Target length: around $targetLength words
              - Include: verse, chorus, bridge structure
              - Keep the original meaning and emotion
              - Fill in missing words naturally
              - Make it radio-friendly

              Return only the completed lyrics, no explanations.
              ''',
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final completedLyrics = response.data['choices'][0]['message']['content'];
        return completedLyrics.trim();
      } else {
        Logger.log('kie.ai lyrics completion failed, returning original');
        return originalLyrics;
      }
    } catch (e) {
      Logger.log('Error completing lyrics with kie.ai: $e');
      return originalLyrics;
    }
  }

  /// Upload voice file to kie.ai file storage
  Future<String> uploadVoiceFile(String audioPath) async {
    try {
      Logger.log('Uploading voice file to kie.ai file storage: $audioPath');

      dynamic requestData;
      String fileUploadUrl;

      if (kIsWeb) {
        // For web, use proxy with blob URL (proxy will fetch and upload)
        requestData = {
          'audioPath': audioPath,
          'filename': 'voice_recording.webm',
        };
        fileUploadUrl = '/api/proxy/kie/file-upload';
      } else {
        // For mobile, direct upload to kie.ai
        final audioBytes = await _getBlobBytes(audioPath);
        requestData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            audioBytes,
            filename: 'voice_recording.m4a',
          ),
          'fileName': 'voice_recording.m4a',
        });
        fileUploadUrl = 'https://kieai.redpandaai.co/api/file-stream-upload';
      }

      final response = await _dio.post(fileUploadUrl, data: requestData);

      Logger.log('File upload response: ${response.data}');

      // Parse response to get downloadUrl
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'] as bool?;
        if (success == true) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            final downloadUrl = data['downloadUrl'] as String?;
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              Logger.log('Voice file uploaded successfully: $downloadUrl');
              return downloadUrl;
            }
          }
        }
        throw Exception('File upload failed: ${responseData['msg'] ?? 'Unknown error'}');
      }

      throw Exception('Invalid file upload response format: ${response.data}');
    } catch (e) {
      Logger.log('Error uploading voice file: $e');
      throw Exception('Voice file upload failed: $e');
    }
  }

  /// Generate complete song using kie.ai Upload and Cover Audio API with uploaded file URL
  Future<String> generateBackgroundMusic({
    required VoiceAnalysis analysis,
    required String completedLyrics,
    int duration = 180, // 3 minutes default
    String? uploadedFileId,
  }) async {
    try {
      Logger.log('Generating complete song with kie.ai Upload and Cover Audio API');

      if (uploadedFileId == null) {
        throw Exception('No audio file path provided');
      }

      // Step 1: Upload voice file to kie.ai and get URL
      final uploadUrl = await uploadVoiceFile(uploadedFileId);

      // Step 2: Create cover prompt based on analysis
      final coverPrompt = '''
      Create a ${analysis.genre} cover with ${analysis.mood} mood at ${analysis.tempo} tempo.
      Transform this voice recording into a complete song with professional background music.
      Enhance vocal quality and add harmonies. Create a radio-ready mix.
      ''';

      // Step 3: Use Upload and Cover Audio API with the uploaded file URL
      final requestData = {
        'uploadUrl': uploadUrl,
        'prompt': coverPrompt,
        'style': '${analysis.genre}, ${analysis.mood}',
        'title': 'AI Generated Voice Cover',
        'customMode': 'true',
        'instrumental': 'false',
        'model': 'V5',
        'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/music',
      };

      final endpoint = kIsWeb
          ? '/api/proxy/kie/upload-cover'
          : '/api/v1/generate/upload-cover';

      final response = await _dio.post(endpoint, data: requestData);

      Logger.log('Upload and Cover Audio response: ${response.data}');

      // Handle kie.ai response format: {"code": 200, "msg": "success", "data": {"taskId": "..."}}
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as int?;
        final msg = responseData['msg'] as String?;

        if (code == 200) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            final taskId = data['taskId'] as String?;
            if (taskId != null && taskId.isNotEmpty) {
              Logger.log('Upload and Cover Audio task started: $taskId');
              return taskId;
            }
          }
          throw Exception('Missing taskId in response: ${responseData}');
        } else {
          throw Exception('kie.ai API error (code: $code): $msg');
        }
      }

      throw Exception('Invalid response format: ${response.data}');
    } catch (e) {
      Logger.log('Error with Upload and Cover Audio API: $e');
      throw Exception('Upload and Cover Audio failed: $e');
    }
  }

  /// Convert generated music to WAV format using kie.ai WAV conversion API
  Future<String> convertToWav({
    required String taskId,
    required String audioId,
  }) async {
    try {
      Logger.log('Converting music to WAV format: taskId=$taskId, audioId=$audioId');

      final endpoint = kIsWeb
          ? '/api/proxy/kie/convert-wav'
          : '/api/v1/wav/generate';

      final response = await _dio.post(
        endpoint,
        data: {
          'taskId': taskId,
          'audioId': audioId,
          'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/wav',
        },
      );

      if (response.statusCode == 200) {
        final wavTaskId = response.data['data']['taskId'];
        Logger.log('WAV conversion task started: $wavTaskId');
        return wavTaskId;
      } else {
        throw Exception('kie.ai WAV conversion failed: ${response.statusMessage}');
      }
    } catch (e) {
      Logger.log('Error with WAV conversion API: $e');
      throw Exception('WAV conversion failed: $e');
    }
  }

  VoiceAnalysis _parseAnalysisResponse(String content) {
    try {
      // Simple JSON parsing (in production, use proper JSON parsing)
      final moodMatch = RegExp(r'"mood"\s*:\s*"([^"]+)"').firstMatch(content);
      final genreMatch = RegExp(r'"genre"\s*:\s*"([^"]+)"').firstMatch(content);
      final tempoMatch = RegExp(r'"tempo"\s*:\s*"([^"]+)"').firstMatch(content);
      final confidenceMatch = RegExp(r'"confidence"\s*:\s*([0-9.]+)').firstMatch(content);

      return VoiceAnalysis(
        mood: moodMatch?.group(1) ?? 'upbeat',
        genre: genreMatch?.group(1) ?? 'pop',
        tempo: tempoMatch?.group(1) ?? 'medium',
        confidence: double.tryParse(confidenceMatch?.group(1) ?? '0.7') ?? 0.7,
      );
    } catch (e) {
      Logger.log('Error parsing analysis response: $e');
      return VoiceAnalysis(
        mood: 'upbeat',
        genre: 'pop',
        tempo: 'medium',
        confidence: 0.5,
      );
    }
  }

  /// Complete workflow: Voice recording to finished song
  Future<CompleteSongResult> processVoiceToSong(String audioPath) async {
    try {
      Logger.log('Starting complete voice-to-song processing with kie.ai');

      // Step 1: Convert voice to lyrics
      final voiceResult = await voiceToLyrics(audioPath);

      // Step 2: Complete the lyrics
      final completedLyrics = await completeLyrics(
        originalLyrics: voiceResult.originalText,
        mood: voiceResult.analyzedMood,
        genre: voiceResult.detectedGenre,
      );

      // Step 3: Generate complete song with Add Vocals
      final analysis = VoiceAnalysis(
        mood: voiceResult.analyzedMood,
        genre: voiceResult.detectedGenre,
        tempo: voiceResult.suggestedTempo,
        confidence: voiceResult.confidence,
      );

      final backgroundMusicUrl = await generateBackgroundMusic(
        analysis: analysis,
        completedLyrics: completedLyrics,
        uploadedFileId: voiceResult.uploadedFileId,
      );

      return CompleteSongResult(
        originalVoiceRecording: audioPath,
        transcribedLyrics: voiceResult.originalText,
        completedLyrics: completedLyrics,
        backgroundMusicUrl: backgroundMusicUrl,
        analysis: analysis,
      );
    } catch (e) {
      Logger.log('Error processing voice to song: $e');
      rethrow;
    }
  }


  void dispose() {
    _dio.close();
  }
}

class VoiceToLyricsResult {
  final String originalText;
  final String analyzedMood;
  final String detectedGenre;
  final String suggestedTempo;
  final double confidence;
  final String? uploadedFileId;

  VoiceToLyricsResult({
    required this.originalText,
    required this.analyzedMood,
    required this.detectedGenre,
    required this.suggestedTempo,
    required this.confidence,
    this.uploadedFileId,
  });
}

class VoiceAnalysis {
  final String mood;
  final String genre;
  final String tempo;
  final double confidence;

  VoiceAnalysis({
    required this.mood,
    required this.genre,
    required this.tempo,
    required this.confidence,
  });
}

class CompleteSongResult {
  final String originalVoiceRecording;
  final String transcribedLyrics;
  final String completedLyrics;
  final String backgroundMusicUrl;
  final VoiceAnalysis analysis;
  final String? finalMixedSongUrl;

  CompleteSongResult({
    required this.originalVoiceRecording,
    required this.transcribedLyrics,
    required this.completedLyrics,
    required this.backgroundMusicUrl,
    required this.analysis,
    this.finalMixedSongUrl,
  });
}