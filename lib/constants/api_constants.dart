class ApiConstants {
  // kie.ai Configuration - use environment variables if available
  static String get kieAiApiKey {
    const envKey = String.fromEnvironment('KIE_AI_API_KEY');
    return envKey.isNotEmpty ? envKey : 'your_kie_ai_api_key_here';
  }

  static const String kieAiBaseUrl = 'https://api.kie.ai/api/v1';

  // Supabase Configuration - use environment variables if available
  static String get supabaseUrl {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    return envUrl.isNotEmpty ? envUrl : 'your_supabase_url';
  }

  static String get supabaseAnonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    return envKey.isNotEmpty ? envKey : 'your_supabase_anon_key';
  }

  // PocketBase Configuration
  static const String pocketBaseUrl = 'your_pocketbase_url';

  // API Endpoints
  static const String musicGeneration = '/generate';
  static const String musicStatus = '/generate/record-info'; // kie.ai task status endpoint
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