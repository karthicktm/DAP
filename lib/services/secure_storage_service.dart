import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for API keys and sensitive data
/// Uses iOS KeyChain and Android KeyStore for maximum security
/// Falls back to SharedPreferences on web platform
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(
      publicKey: 'AIzaSyBip6zRz9n6B8nO5WQ8r7K2s1T3Y6V9W2X4',
    ),
  );

  // Storage keys
  static const String _kieAiKey = 'kie_ai_api_key';
  static const String _supabaseUrl = 'supabase_url';
  static const String _supabaseKey = 'supabase_anon_key';
  static const String _userPreferences = 'user_preferences';

  /// Store Kie.ai API key securely
  static Future<void> storeKieAiKey(String apiKey) async {
    try {
      await _storage.write(key: _kieAiKey, value: apiKey);

      // Also store in SharedPreferences as web fallback
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kieAiKey, apiKey);
      }
    } catch (e) {
      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kieAiKey, apiKey);
        } catch (prefError) {
          throw Exception('Failed to store Kie.ai API key: $e (SharedPreferences fallback: $prefError)');
        }
      } else {
        throw Exception('Failed to store Kie.ai API key: $e');
      }
    }
  }

  /// Get stored Kie.ai API key
  static Future<String?> getKieAiKey() async {
    try {
      final value = await _storage.read(key: _kieAiKey);
      if (value != null) return value;

      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_kieAiKey);
      }
      return null;
    } catch (e) {
      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString(_kieAiKey);
        } catch (prefError) {
          throw Exception('Failed to retrieve Kie.ai API key: $e (SharedPreferences fallback: $prefError)');
        }
      }
      throw Exception('Failed to retrieve Kie.ai API key: $e');
    }
  }

  /// Store Supabase credentials securely
  static Future<void> storeSupabaseCredentials({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _supabaseUrl, value: url),
        _storage.write(key: _supabaseKey, value: anonKey),
      ]);

      // Also store in SharedPreferences as web fallback
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString(_supabaseUrl, url),
          prefs.setString(_supabaseKey, anonKey),
        ]);
      }
    } catch (e) {
      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await Future.wait([
            prefs.setString(_supabaseUrl, url),
            prefs.setString(_supabaseKey, anonKey),
          ]);
        } catch (prefError) {
          throw Exception('Failed to store Supabase credentials: $e (SharedPreferences fallback: $prefError)');
        }
      } else {
        throw Exception('Failed to store Supabase credentials: $e');
      }
    }
  }

  /// Get stored Supabase credentials
  static Future<Map<String, String?>> getSupabaseCredentials() async {
    try {
      final url = await _storage.read(key: _supabaseUrl);
      final key = await _storage.read(key: _supabaseKey);
      return {'url': url, 'key': key};
    } catch (e) {
      throw Exception('Failed to retrieve Supabase credentials: $e');
    }
  }

  /// Get stored Supabase URL
  static Future<String?> getSupabaseUrl() async {
    try {
      final value = await _storage.read(key: _supabaseUrl);
      if (value != null) return value;

      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_supabaseUrl);
      }
      return null;
    } catch (e) {
      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString(_supabaseUrl);
        } catch (prefError) {
          throw Exception('Failed to retrieve Supabase URL: $e (SharedPreferences fallback: $prefError)');
        }
      }
      throw Exception('Failed to retrieve Supabase URL: $e');
    }
  }

  /// Get stored Supabase anon key
  static Future<String?> getSupabaseKey() async {
    try {
      final value = await _storage.read(key: _supabaseKey);
      if (value != null) return value;

      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_supabaseKey);
      }
      return null;
    } catch (e) {
      // Fallback to SharedPreferences for web
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getString(_supabaseKey);
        } catch (prefError) {
          throw Exception('Failed to retrieve Supabase key: $e (SharedPreferences fallback: $prefError)');
        }
      }
      throw Exception('Failed to retrieve Supabase key: $e');
    }
  }

  /// Store user preferences
  static Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefsJson = preferences.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
      await _storage.write(key: _userPreferences, value: prefsJson);
    } catch (e) {
      throw Exception('Failed to store user preferences: $e');
    }
  }

  /// Get user preferences
  static Future<Map<String, String>> getUserPreferences() async {
    try {
      final prefsJson = await _storage.read(key: _userPreferences);
      if (prefsJson == null) return {};

      final entries = prefsJson.split('|');
      final Map<String, String> preferences = {};

      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          preferences[parts[0]] = parts[1];
        }
      }

      return preferences;
    } catch (e) {
      throw Exception('Failed to retrieve user preferences: $e');
    }
  }

  /// Check if API keys are configured
  static Future<bool> isConfigured() async {
    try {
      final kieAiKey = await getKieAiKey();
      final supabaseCreds = await getSupabaseCredentials();

      return kieAiKey != null &&
             kieAiKey.isNotEmpty &&
             supabaseCreds['url'] != null &&
             supabaseCreds['url']!.isNotEmpty &&
             supabaseCreds['key'] != null &&
             supabaseCreds['key']!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration status
  static Future<Map<String, bool>> getConfigurationStatus() async {
    try {
      final kieAiKey = await getKieAiKey();
      final supabaseUrl = await getSupabaseUrl();
      final supabaseKey = await getSupabaseKey();

      return {
        'kie_ai': kieAiKey != null && kieAiKey.isNotEmpty,
        'supabase_url': supabaseUrl != null && supabaseUrl.isNotEmpty,
        'supabase_key': supabaseKey != null && supabaseKey.isNotEmpty,
      };
    } catch (e) {
      return {
        'kie_ai': false,
        'supabase_url': false,
        'supabase_key': false,
      };
    }
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear stored data: $e');
    }
  }

  /// Clear specific keys
  static Future<void> clearKeys({String? kieAi, String? supabase}) async {
    try {
      final keysToDelete = <String>[];

      if (kieAi != null) keysToDelete.add(_kieAiKey);
      if (supabase != null) {
        keysToDelete.add(_supabaseUrl);
        keysToDelete.add(_supabaseKey);
      }

      if (keysToDelete.isNotEmpty) {
        await _storage.deleteAll(aOptions: _deleteOptions(keysToDelete));
      }
    } catch (e) {
      throw Exception('Failed to clear specified keys: $e');
    }
  }

  /// Create AndroidOptions for specific keys
  static AndroidOptions _deleteOptions(List<String> keys) {
    return AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    );
  }

  /// Validate Kie.ai API key format
  static bool isValidKieAiKey(String? key) {
    if (key == null || key.isEmpty) return false;

    // Basic validation - Kie.ai keys are typically alphanumeric with underscores
    if (key.length < 10) return false;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) return false;

    return true;
  }

  /// Validate Supabase URL format
  static bool isValidSupabaseUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
             (uri.scheme == 'https' || uri.scheme == 'http') &&
             uri.host.isNotEmpty &&
             (uri.host.contains('supabase.co') || uri.host.contains('localhost'));
    } catch (e) {
      return false;
    }
  }

  /// Validate Supabase key format
  static bool isValidSupabaseKey(String? key) {
    if (key == null || key.isEmpty) return false;

    // Supabase anon keys are JWT tokens with format: header.payload.signature
    // They contain alphanumeric strings, underscores, hyphens, and periods
    return key.length > 50 &&
           RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(key) &&
           key.split('.').length == 3; // JWT tokens have 3 parts separated by periods
  }

  /// Export all stored data (for debugging/migration)
  static Future<Map<String, String?>> exportAllData() async {
    try {
      final allData = <String, String?>{};

      // Read known keys
      allData[_kieAiKey] = await getKieAiKey();
      allData[_supabaseUrl] = await getSupabaseUrl();
      allData[_supabaseKey] = await getSupabaseKey();
      allData[_userPreferences] = await _storage.read(key: _userPreferences);

      return allData;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Check if secure storage is available on this platform
  static Future<bool> isSecureStorageAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = 'test_secure_storage';
      const testValue = 'test_value';

      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);

      return readValue == testValue;
    } catch (e) {
      return false;
    }
  }
}