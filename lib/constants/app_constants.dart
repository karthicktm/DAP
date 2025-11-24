class AppConstants {
  // App Info
  static const String appName = 'AI Radio Platform';
  static const String appVersion = '1.0.0';
  static const bool isProduction = false;

  // UI Constants
  static const double borderRadius = 16.0;
  static const double padding = 16.0;
  static const double spacing = 8.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Audio Settings
  static const double volumeMax = 1.0;
  static const double volumeMin = 0.0;
  static const double volumeDefault = 0.7;

  // Chat Settings
  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userProfileKey = 'user_profile';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'theme_mode';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ar'];
  static const String defaultLanguage = 'en';

  // Audio Formats
  static const List<String> supportedAudioFormats = [
    'mp3', 'wav', 'aac', 'm4a', 'flac'
  ];

  // File Sizes
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxAudioUploadSize = 100 * 1024 * 1024; // 100MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache Settings
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Performance
  static const int maxConcurrentDownloads = 3;
  static const Duration debounceDelay = Duration(milliseconds: 300);
}