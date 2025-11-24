class ApiConstants {
  // kie.ai Configuration
  static const String kieAiApiKey = 'your_kie_ai_api_key_here';
  static const String kieAiBaseUrl = 'https://api.kie.ai/api/v1';

  // Supabase Configuration
  static const String supabaseUrl = 'your_supabase_url';
  static const String supabaseAnonKey = 'your_supabase_anon_key';

  // PocketBase Configuration
  static const String pocketBaseUrl = 'your_pocketbase_url';

  // API Endpoints
  static const String musicGeneration = '/generate';
  static const String musicStatus = '/status/'; // Add status checking endpoint
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