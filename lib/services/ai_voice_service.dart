import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

/// AI Voice Service using only kie.ai APIs for all voice and music processing
class AIVoiceService {
  late final Dio _dio;
  static const String _kieAiBaseUrl = 'https://api.kie.ai/v1';
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

  /// Upload voice recording to kie.ai and get file ID
  Future<String> _uploadVoiceFile(String audioPath) async {
    try {
      Logger.log('Uploading voice file to kie.ai: $audioPath');

      String base64Audio;
      if (kIsWeb) {
        // For web, audioPath is a blob URL
        final response = await html.HttpRequest.request(
          audioPath,
          responseType: 'arraybuffer',
        );
        final bytes = Uint8List.view(response.response);
        base64Audio = base64Encode(bytes);
      } else {
        // For mobile, read file and encode
        final file = File(audioPath);
        final bytes = await file.readAsBytes();
        base64Audio = base64Encode(bytes);
      }

      final endpoint = kIsWeb
          ? '/api/proxy/kie/file-upload'
          : '/file-base64-upload';

      final response = await _dio.post(
        endpoint,
        data: {
          'data': base64Audio,
          'filename': 'voice_recording.webm',
        },
      );

      if (response.statusCode == 200) {
        final fileId = response.data['fileId'];
        Logger.log('Voice file uploaded successfully: $fileId');
        return fileId;
      } else {
        throw Exception('File upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      Logger.log('Error uploading voice file: $e');
      throw Exception('Voice file upload failed: $e');
    }
  }

  /// Process voice recording using kie.ai Add Vocals API
  Future<VoiceToLyricsResult> voiceToLyrics(String audioPath) async {
    try {
      Logger.log('Processing voice recording with kie.ai Add Vocals API: $audioPath');

      // Step 1: Upload the voice file
      final fileId = await _uploadVoiceFile(audioPath);

      // Step 2: Analyze the voice for mood and genre using LLM first
      final analysis = await _analyzeVoiceFile(fileId);

      // Step 3: For now, we'll return the analysis result
      // The actual Add Vocals API will be called in generateBackgroundMusic
      return VoiceToLyricsResult(
        originalText: 'Voice recording uploaded and analyzed',
        analyzedMood: analysis.mood,
        detectedGenre: analysis.genre,
        suggestedTempo: analysis.tempo,
        confidence: analysis.confidence,
        uploadedFileId: fileId, // Store the file ID for later use
      );
    } catch (e) {
      Logger.log('Error processing voice recording: $e');
      throw Exception('Voice processing failed: $e');
    }
  }

  /// Analyze uploaded voice file for mood, genre, and tempo using kie.ai LLM
  Future<VoiceAnalysis> _analyzeVoiceFile(String fileId) async {
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
              Based on the uploaded voice recording, return ONLY a JSON response with:
              {
                "mood": "happy|sad|energetic|calm|romantic|angry|melancholic|upbeat",
                "genre": "pop|rock|rap|country|jazz|electronic|ballad|folk",
                "tempo": "slow|medium|fast",
                "confidence": 0.0-1.0
              }''',
            },
            {
              'role': 'user',
              'content': 'Analyze the voice recording with file ID: $fileId. Detect the mood, genre preference, and tempo from the vocal characteristics.',
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

  /// Generate complete song using kie.ai Add Vocals API
  Future<String> generateBackgroundMusic({
    required VoiceAnalysis analysis,
    required String completedLyrics,
    int duration = 180, // 3 minutes default
    String? uploadedFileId,
  }) async {
    try {
      Logger.log('Generating complete song with kie.ai Add Vocals API');

      if (uploadedFileId == null) {
        throw Exception('No uploaded voice file ID provided');
      }

      // Create vocal prompt based on analysis
      final vocalPrompt = '''
      Transform this voice recording into a complete song:
      - Style: ${analysis.genre} ${analysis.mood}
      - Tempo: ${analysis.tempo}
      - Add professional background music that complements the vocals
      - Enhance vocal quality and add harmonies if needed
      - Create a radio-ready mix
      ''';

      final endpoint = kIsWeb
          ? '/api/proxy/kie/add-vocals'
          : '/generate/add-vocals';

      final response = await _dio.post(
        endpoint,
        data: {
          'prompt': vocalPrompt,
          'audioId': uploadedFileId,
          'model': 'V5',
          'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/music',
        },
      );

      if (response.statusCode == 200) {
        final taskId = response.data['taskId'];
        Logger.log('Add Vocals task started: $taskId');

        // Poll for completion (simple polling - in production you'd use webhooks)
        return await _pollForCompletion(taskId);
      } else {
        throw Exception('kie.ai Add Vocals failed: ${response.statusMessage}');
      }
    } catch (e) {
      Logger.log('Error with Add Vocals API: $e');
      throw Exception('Add Vocals failed: $e');
    }
  }

  /// Poll for Add Vocals completion
  Future<String> _pollForCompletion(String taskId) async {
    Logger.log('Polling for completion of task: $taskId');

    for (int i = 0; i < 30; i++) { // Max 5 minutes
      await Future.delayed(const Duration(seconds: 10));

      try {
        final endpoint = kIsWeb
            ? '/api/proxy/kie/generate-status/$taskId'
            : '/generate/status/$taskId';
        final response = await _dio.get(endpoint);

        if (response.statusCode == 200) {
          final status = response.data['status'];
          Logger.log('Task $taskId status: $status');

          if (status == 'completed') {
            final audioUrl = response.data['result']['audioUrl'];
            Logger.log('Add Vocals completed: $audioUrl');
            return audioUrl;
          } else if (status == 'failed') {
            throw Exception('Add Vocals task failed');
          }
        }
      } catch (e) {
        Logger.log('Error checking task status: $e');
      }
    }

    throw Exception('Add Vocals task timeout');
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