import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // AI Music API Configuration - prioritize Railway env vars, then .env, then fallback
  static String get kieAiApiKey {
    // Try .env file first (loaded by dotenv)
    final envKey = dotenv.env['KIE_AI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty && envKey != 'your_kie_ai_api_key_here') {
      return envKey;
    }

    // Try compile-time environment variable (for development)
    const compileKey = String.fromEnvironment('KIE_AI_API_KEY');
    if (compileKey.isNotEmpty) {
      return compileKey;
    }

    return '2ecfa565693e419f371eff8c5da05833'; // Your provided key as fallback
  }

  static const String kieAiBaseUrl = 'https://api.kie.ai/api/v1';

  // Supabase Configuration - use environment variables properly
  static String get supabaseUrl {
    // Try .env file first (loaded by dotenv) - Railway env vars should be here
    final envUrl = dotenv.env['SUPABASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty && envUrl != 'your_supabase_project_url') {
      return envUrl;
    }

    // Try compile-time environment variable (for development)
    const compileUrl = String.fromEnvironment('SUPABASE_URL');
    if (compileUrl.isNotEmpty) {
      return compileUrl;
    }

    return 'your_supabase_url';
  }

  static String get supabaseAnonKey {
    // Try .env file first (loaded by dotenv) - Railway env vars should be here
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envKey != null && envKey.isNotEmpty && envKey != 'your_supabase_anon_key') {
      return envKey;
    }

    // Try compile-time environment variable (for development)
    const compileKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (compileKey.isNotEmpty) {
      return compileKey;
    }

    return 'your_supabase_anon_key';
  }

  // PocketBase Configuration
  static const String pocketBaseUrl = 'your_pocketbase_url';

  // API Endpoints
  static const String musicGeneration = '/generate';
  static const String musicStatus = '/generate/record-info'; // AI task status endpoint
  static const String imageGeneration = '/image/generate';
  static const String llmGeneration = '/llm/generate';
  static const String audioStems = '/audio/separate-stems';

  // Audio Settings
  static const int maxAudioDuration = 300; // 5 minutes
  static const int defaultAudioBitrate = 320;
  static const int sampleRate = 44100;

  // File Upload Limits
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> supportedAudioFormats = [
    'mp3', 'wav', 'm4a', 'aac', 'flac'
  ];

  // Chat Settings
  static const int maxMessageLength = 500;
  static const int maxChatHistory = 100;

  // Rate Limiting
  static const int maxMusicGenerationsPerHour = 10;
  static const int maxImageGenerationsPerHour = 20;
}