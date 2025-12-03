import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

/// AI Voice Service using only kie.ai APIs for all voice and music processing
class AIVoiceService {
  late final Dio _dio;
  static const String _baseUrl = 'https://api.kie.ai/v1';

  AIVoiceService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.kieAiApiKey}',
        'Content-Type': 'application/json',
      },
    ));

    if (!kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (obj) => Logger.log(obj.toString()),
      ));
    }
  }

  /// Convert voice recording to lyrics using kie.ai speech-to-text
  /// NOTE: Kie.ai does not currently offer speech-to-text API
  /// This is a placeholder implementation that provides mock transcription
  Future<VoiceToLyricsResult> voiceToLyrics(String audioPath) async {
    try {
      Logger.log('Processing voice recording: $audioPath');

      // Since Kie.ai doesn't offer speech-to-text API, we'll use a mock implementation
      // In a real app, you would integrate with OpenAI Whisper, Google Speech-to-Text,
      // or another speech-to-text service
      Logger.log('⚠️ Using mock transcription - Kie.ai does not offer speech-to-text API');

      await Future.delayed(const Duration(seconds: 2)); // Simulate processing time

      // Generate mock lyrics based on recording
      final mockLyrics = _generateMockLyrics();

      // Analyze the mock lyrics for mood and structure using kie.ai LLM
      final analysis = await _analyzeVoiceContentWithKieAI(mockLyrics);

      return VoiceToLyricsResult(
        originalText: mockLyrics,
        analyzedMood: analysis.mood,
        detectedGenre: analysis.genre,
        suggestedTempo: analysis.tempo,
        confidence: 0.8, // Mock confidence
      );
    } catch (e) {
      Logger.log('Error processing voice recording: $e');
      throw Exception('Voice processing failed: $e');
    }
  }

  /// Generate mock lyrics for demonstration
  String _generateMockLyrics() {
    final sampleLyrics = [
      "Love is in the air tonight, stars are shining bright, everything feels right",
      "Dancing through the city lights, music fills the night, everything's alright",
      "Dreams are calling out to me, set my spirit free, this is where I want to be",
      "Sunshine on my face today, washing fears away, let the music play",
      "Walking down this empty street, to my favorite beat, life feels so complete"
    ];

    final random = DateTime.now().millisecondsSinceEpoch % sampleLyrics.length;
    return sampleLyrics[random];
  }

  /// Analyze voice content for mood, genre, and tempo using kie.ai LLM
  Future<VoiceAnalysis> _analyzeVoiceContentWithKieAI(String text) async {
    try {
      final response = await _dio.post(
        '/llm/generate',
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a music AI that analyzes lyrics for mood, genre, and tempo.
              Analyze the given text and return ONLY a JSON response with:
              {
                "mood": "happy|sad|energetic|calm|romantic|angry|melancholic|upbeat",
                "genre": "pop|rock|rap|country|jazz|electronic|ballad|folk",
                "tempo": "slow|medium|fast",
                "confidence": 0.0-1.0
              }''',
            },
            {
              'role': 'user',
              'content': 'Analyze this text: "$text"',
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
          confidence: 0.5,
        );
      }
    } catch (e) {
      Logger.log('Error analyzing voice content with kie.ai: $e');
      return VoiceAnalysis(
        mood: 'upbeat',
        genre: 'pop',
        tempo: 'medium',
        confidence: 0.5,
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

      final response = await _dio.post(
        '/llm/generate',
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

  /// Generate background music based on voice analysis using kie.ai
  Future<String> generateBackgroundMusic({
    required VoiceAnalysis analysis,
    required String completedLyrics,
    int duration = 180, // 3 minutes default
  }) async {
    try {
      Logger.log('Generating background music with kie.ai for mood: ${analysis.mood}');

      // Create a music prompt based on voice analysis
      final musicPrompt = '''
      Create instrumental background music for vocals with these characteristics:
      - Mood: ${analysis.mood}
      - Genre: ${analysis.genre}
      - Tempo: ${analysis.tempo}
      - Duration: ${duration}s
      - Style: Leave space for vocals, supporting instrumental
      - Energy level: ${_getEnergyLevel(analysis.mood)}
      ''';

      final response = await _dio.post(
        '/suno/generate',
        data: {
          'prompt': musicPrompt,
          'genre': analysis.genre,
          'mood': analysis.mood,
          'include_lyrics': false, // Instrumental only
          'duration': duration,
          'model': 'suno-v3',
          'instrumental': true, // Request instrumental version
        },
      );

      if (response.statusCode == 200) {
        final audioUrl = response.data['audio_url'] ?? '';
        Logger.log('Background music generated successfully: $audioUrl');
        return audioUrl;
      } else {
        throw Exception('kie.ai music generation failed: ${response.statusMessage}');
      }
    } catch (e) {
      Logger.log('Error generating background music with kie.ai: $e');
      throw Exception('Background music generation failed: $e');
    }
  }

  String _getEnergyLevel(String mood) {
    switch (mood.toLowerCase()) {
      case 'energetic':
      case 'upbeat':
      case 'happy':
        return 'high';
      case 'calm':
      case 'melancholic':
      case 'sad':
        return 'low';
      default:
        return 'medium';
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

      // Step 3: Generate background music
      final analysis = VoiceAnalysis(
        mood: voiceResult.analyzedMood,
        genre: voiceResult.detectedGenre,
        tempo: voiceResult.suggestedTempo,
        confidence: voiceResult.confidence,
      );

      final backgroundMusicUrl = await generateBackgroundMusic(
        analysis: analysis,
        completedLyrics: completedLyrics,
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

  VoiceToLyricsResult({
    required this.originalText,
    required this.analyzedMood,
    required this.detectedGenre,
    required this.suggestedTempo,
    required this.confidence,
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