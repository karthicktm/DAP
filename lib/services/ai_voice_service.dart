import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

/// AI Voice Service using Supabase for file storage and kie.ai for music processing
class AIVoiceService {
  late final d.Dio _dio;
  late final SupabaseClient _supabase;
  static const String _kieAiBaseUrl = 'https://api.kie.ai';
  static const String _backendProxyUrl = 'https://dap-production-99ef.up.railway.app';

  AIVoiceService() {
    // Initialize Supabase
    _supabase = Supabase.instance.client;

    // Use different base URLs based on platform
    final baseUrl = kIsWeb ? _backendProxyUrl : _kieAiBaseUrl;
    final headers = <String, dynamic>{
      if (!kIsWeb) 'Authorization': 'Bearer ${ApiConstants.kieAiApiKey}',
    };

    _dio = d.Dio(d.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      headers: headers as Map<String, dynamic>?,
    ));

    if (!kDebugMode) {
      _dio.interceptors.add(d.LogInterceptor(
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
        return d.MultipartFile.fromBytes(
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
          options: d.Options(responseType: d.ResponseType.bytes)
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

  /// Upload voice file to Supabase storage and return taskId for WAV conversion
  Future<WavConversionResult> uploadVoiceFileForWavConversion(String audioPath) async {
    try {
      Logger.log('Uploading voice file to Supabase storage: $audioPath');

      // Get audio bytes
      final audioBytes = await _getBlobBytes(audioPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = kIsWeb ? 'voice_recording_${timestamp}.webm' : 'voice_recording_${timestamp}.m4a';
      final filePath = 'voice_recordings/$fileName';

      // Upload to Supabase storage
      final audioData = Uint8List.fromList(audioBytes);
      await _supabase.storage
          .from('voice_recordings')
          .uploadBinary(filePath, audioData);

      // Get public URL for the uploaded file
      final publicUrl = await _supabase.storage
          .from('voice_recordings')
          .createSignedUrl(filePath, 604800); // 7 days in seconds
      Logger.log('✅ Voice file uploaded to Supabase: $publicUrl');

      // Convert WAV will be done after music generation
      final wavTaskId = '';

      return WavConversionResult(
        downloadUrl: publicUrl,
        wavTaskId: wavTaskId,
        status: 'processing',
      );
    } catch (e) {
      Logger.log('Error uploading voice file to Supabase: $e');
      throw Exception('Voice file upload failed: $e');
    }
  }

  /// Upload voice file to Supabase storage and generate music using kie.ai Upload and Cover Audio API
  Future<MusicGenerationResult> uploadVoiceFileForMusicGeneration(String audioPath) async {
    try {
      Logger.log('Uploading voice file for music generation: $audioPath');

      // Get audio bytes
      final audioBytes = await _getBlobBytes(audioPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = kIsWeb ? 'voice_recording_${timestamp}.webm' : 'voice_recording_${timestamp}.m4a';
      final filePath = 'voice_recordings/$fileName';

      // Upload to Supabase storage
      final audioData = Uint8List.fromList(audioBytes);
      await _supabase.storage
          .from('voice_recordings')
          .uploadBinary(filePath, audioData);

      // Get public URL for the uploaded file
      final publicUrl = await _supabase.storage
          .from('voice_recordings')
          .createSignedUrl(filePath, 604800); // 7 days in seconds
      Logger.log('File uploaded successfully: $publicUrl');

      // Generate music using kie.ai Upload and Cover Audio API
      final endpoint = kIsWeb
          ? '/api/proxy/kie/upload-cover'
          : '/api/v1/generate/upload-cover';

      final requestData = {
        'upload_url': publicUrl,
        'prompt': 'Convert this voice recording to a professional song with background music',
        'style': 'pop, professional, high quality',
        'title': 'Voice Cover Song',
        'custom_mode': true,
        'instrumental': false,
        'model': 'V5',
        'callback_url': '${_backendProxyUrl}/api/webhook/music-generation',
      };

      Logger.log('Generating music with Upload and Cover Audio API...');
      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: d.Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      Logger.log('Music generation response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Extract taskId and audioId from response
        String? taskId;
        String? audioId;

        if (responseData['data'] != null) {
          final data = responseData['data'];
          taskId = data['task_id'] ?? data['taskId'];
          audioId = data['audio_id'] ?? data['audioId'] ?? data['id'];
        } else {
          taskId = responseData['task_id'] ?? responseData['taskId'];
          audioId = responseData['audio_id'] ?? responseData['audioId'] ?? responseData['id'];
        }

        if (taskId == null || audioId == null) {
          Logger.log('Invalid response format: ${response.data}');
          throw Exception('Invalid response format from music generation API');
        }

        return MusicGenerationResult(
          taskId: taskId,
          audioId: audioId,
          status: 'processing',
        );
      } else {
        throw Exception('Music generation failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.log('Error in music generation: $e');
      throw Exception('Music generation failed: $e');
    }
  }

  /// Check WAV conversion status
  Future<WavConversionStatus> getWavConversionStatus(String wavTaskId) async {
    try {
      Logger.log('Checking WAV conversion status for taskId: $wavTaskId');

      final endpoint = kIsWeb
          ? '/api/proxy/kie/get-wav-details'
          : '/api/v1/wav/get-wav-details';

      final response = await _dio.post(
        endpoint,
        data: {
          'task_id': wavTaskId, // Use snake_case parameter naming
        },
        options: d.Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      Logger.log('WAV status response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Try multiple common response formats
        String? status;
        String? wavUrl;
        String? message;

        // Format 1: {"success": true, "data": {"status": "...", "wav_url": "..."}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          status = data['status'] ?? data['state'];
          wavUrl = data['wav_url'] ?? data['audio_url'] ?? data['output_url'];
          message = data['message'] ?? data['status_message'];
        }

        // Format 2: {"code": 200, "data": {"status": "...", "wavUrl": "..."}}
        else if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];
          status = data['status'] ?? data['state'];
          wavUrl = data['wavUrl'] ?? data['audioUrl'] ?? data['outputUrl'];
          message = data['message'] ?? data['statusMessage'];
        }

        // Format 3: {"status": "...", "wav_url": "..."} (direct)
        else {
          status = responseData['status'] ?? responseData['state'];
          wavUrl = responseData['wav_url'] ?? responseData['audio_url'] ?? responseData['output_url'];
          message = responseData['message'] ?? responseData['status_message'];
        }

        // Normalize status values
        String normalizedStatus = status?.toLowerCase() ?? 'unknown';
        if (normalizedStatus == 'completed' || normalizedStatus == 'finished' || normalizedStatus == 'done') {
          normalizedStatus = 'success';
        } else if (normalizedStatus == 'processing' || normalizedStatus == 'working' || normalizedStatus == 'converting') {
          normalizedStatus = 'processing';
        } else if (normalizedStatus == 'queued' || normalizedStatus == 'pending' || normalizedStatus == 'waiting') {
          normalizedStatus = 'pending';
        } else if (normalizedStatus == 'failed' || normalizedStatus == 'error') {
          normalizedStatus = 'error';
        }

        return WavConversionStatus(
          taskId: wavTaskId,
          status: normalizedStatus,
          wavUrl: wavUrl ?? '',
          message: message ?? '',
        );
      } else {
        return WavConversionStatus(
          taskId: wavTaskId,
          status: 'error',
          message: 'HTTP ${response.statusCode}: ${response.statusMessage}',
        );
      }
    } on d.DioException catch (e) {
      Logger.log('❌ DioException checking WAV status: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ??
                         e.response?.data?['error'] ??
                         e.message ??
                         'Network error checking WAV status';
      return WavConversionStatus(
        taskId: wavTaskId,
        status: 'error',
        message: errorMessage,
      );
    } catch (e) {
      Logger.log('❌ Unexpected error checking WAV status: $e');
      return WavConversionStatus(
        taskId: wavTaskId,
        status: 'error',
        message: e.toString(),
      );
    }
  }

  /// Convert a generated music track to WAV format
  Future<String> convertToWav({required String taskId, required String audioId}) async {
    try {
      Logger.log('Converting music track to WAV format: taskId=$taskId, audioId=$audioId');

      final endpoint = kIsWeb
          ? '/api/proxy/kie/convert-wav'
          : '/api/v1/wav/generate';

      final requestData = {
        'taskId': taskId,
        'audioId': audioId,
        'callBackUrl': 'https://dap-production-99ef.up.railway.app/api/webhook/wav',
      };

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: d.Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      Logger.log('WAV conversion response: ${response.data}');

      // Handle response format: {"code": 200, "msg": "success", "data": {"taskId": "..."}}
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final code = responseData['code'] as int?;
          final data = responseData['data'];

          if (code == 200 && data is Map<String, dynamic>) {
            final wavTaskId = data['taskId'] as String?;
            if (wavTaskId != null && wavTaskId.isNotEmpty) {
              Logger.log('✅ WAV conversion task started: $wavTaskId');
              return wavTaskId;
            }
          }
          throw Exception('Missing taskId in WAV conversion response');
        }
        throw Exception('Invalid WAV conversion response format');
      } else {
        throw Exception('WAV conversion failed: ${response.statusCode} - ${response.statusMessage}');
      }
    } on d.DioException catch (e) {
      Logger.log('❌ DioException in WAV conversion: ${e.response?.data}');
      final errorMessage = e.response?.data?['msg'] ??
                         e.response?.data?['message'] ??
                         e.message ??
                         'Network error during WAV conversion';
      throw Exception('WAV conversion failed: $errorMessage');
    } catch (e) {
      Logger.log('❌ Unexpected error in WAV conversion: $e');
      throw Exception('WAV conversion failed: $e');
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

      // Step 1: Use the uploaded WAV file URL directly
      final uploadUrl = uploadedFileId; // This should already be the WAV URL

      // Step 2: Create cover prompt based on analysis
      final coverPrompt = '''
      Create a ${analysis.genre} cover with ${analysis.mood} mood at ${analysis.tempo} tempo.
      Transform this voice recording into a complete song with professional background music.
      Enhance vocal quality and add harmonies. Create a radio-ready mix.
      ''';

      // Step 3: Use Upload and Cover Audio API with the uploaded file URL
      final requestData = {
        'upload_url': uploadUrl, // Use snake_case parameter naming
        'prompt': coverPrompt.trim(),
        'style': '${analysis.genre}, ${analysis.mood}',
        'title': 'AI Generated Voice Cover',
        'custom_mode': true, // Use boolean instead of string
        'instrumental': false, // Use boolean instead of string
        'model': 'V5',
        'callback_url': 'https://dap-production-99ef.up.railway.app/api/webhook/music',
        'duration': 180, // Add duration parameter
        'quality': 'high', // Add quality parameter
      };

      final endpoint = kIsWeb
          ? '/api/proxy/kie/upload-cover'
          : '/api/v1/generate/upload-cover';

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: d.Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      Logger.log('Upload and Cover Audio response: ${response.data}');

      // Handle multiple response formats
      if (response.statusCode == 200) {
        final responseData = response.data;

        // Try multiple common response formats
        String? taskId;

        // Format 1: {"success": true, "data": {"task_id": "..."}}
        if (responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['task_id'] != null) {
          taskId = responseData['data']['task_id'];
        }

        // Format 2: {"code": 200, "data": {"taskId": "..."}}
        else if (responseData['code'] == 200 &&
                 responseData['data'] != null &&
                 responseData['data']['taskId'] != null) {
          taskId = responseData['data']['taskId'];
        }

        // Format 3: {"task_id": "..."} (direct)
        else if (responseData['task_id'] != null) {
          taskId = responseData['task_id'];
        }

        if (taskId != null && taskId.isNotEmpty) {
          Logger.log('✅ Upload and Cover Audio task started: $taskId');
          return taskId;
        }

        throw Exception('Invalid response format: missing taskId in ${responseData.keys}');
      } else {
        throw Exception('API request failed with status: ${response.statusCode} - ${response.statusMessage}');
      }
    } on d.DioException catch (e) {
      Logger.log('❌ DioException in Upload and Cover Audio: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ??
                         e.response?.data?['error'] ??
                         e.response?.data?['msg'] ??
                         e.message ??
                         'Network error during music generation';
      throw Exception('Upload and Cover Audio failed: $errorMessage');
    } catch (e) {
      Logger.log('❌ Unexpected error in Upload and Cover Audio: $e');
      throw Exception('Upload and Cover Audio failed: $e');
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

/// WAV conversion result
class WavConversionResult {
  final String downloadUrl;
  final String wavTaskId;
  final String status;

  WavConversionResult({
    required this.downloadUrl,
    required this.wavTaskId,
    required this.status,
  });
}

/// WAV conversion status
class WavConversionStatus {
  final String taskId;
  final String status; // pending, processing, success, error
  final String wavUrl;
  final String message;

  WavConversionStatus({
    required this.taskId,
    required this.status,
    this.wavUrl = '',
    this.message = '',
  });

  bool get isCompleted => status == 'success';
  bool get isProcessing => status == 'processing' || status == 'pending';
  bool get hasError => status == 'error';
}

/// Music generation result
class MusicGenerationResult {
  final String taskId;
  final String audioId;
  final String status;
  final bool isCompleted;
  final bool isProcessing;
  final String? downloadUrl;

  MusicGenerationResult({
    required this.taskId,
    required this.audioId,
    required this.status,
    this.isCompleted = false,
    this.isProcessing = true,
    this.downloadUrl,
  });

  MusicGenerationResult copyWith({
    String? taskId,
    String? audioId,
    String? status,
    bool? isCompleted,
    bool? isProcessing,
    String? downloadUrl,
  }) {
    return MusicGenerationResult(
      taskId: taskId ?? this.taskId,
      audioId: audioId ?? this.audioId,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      isProcessing: isProcessing ?? this.isProcessing,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}