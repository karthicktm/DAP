import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';

/// Settings state data class
class SettingsState {
  final String? kieAiKey;
  final String? supabaseUrl;
  final String? supabaseKey;
  final bool isLoading;
  final String? error;
  final Map<String, bool> configurationStatus;

  const SettingsState({
    this.kieAiKey,
    this.supabaseUrl,
    this.supabaseKey,
    this.isLoading = false,
    this.error,
    this.configurationStatus = const {
      'kie_ai': false,
      'supabase_url': false,
      'supabase_key': false,
    },
  });

  SettingsState copyWith({
    String? kieAiKey,
    String? supabaseUrl,
    String? supabaseKey,
    bool? isLoading,
    String? error,
    Map<String, bool>? configurationStatus,
  }) {
    return SettingsState(
      kieAiKey: kieAiKey ?? this.kieAiKey,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseKey: supabaseKey ?? this.supabaseKey,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      configurationStatus: configurationStatus ?? this.configurationStatus,
    );
  }

  bool get isFullyConfigured =>
      configurationStatus['kie_ai'] == true &&
      configurationStatus['supabase_url'] == true &&
      configurationStatus['supabase_key'] == true;

  bool get hasError => error != null;
}

/// Settings notifier for managing settings state
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  /// Load settings from secure storage
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final kieAiKey = await SecureStorageService.getKieAiKey();
      final supabaseUrl = await SecureStorageService.getSupabaseUrl();
      final supabaseKey = await SecureStorageService.getSupabaseKey();
      final configStatus = await SecureStorageService.getConfigurationStatus();

      state = state.copyWith(
        kieAiKey: kieAiKey,
        supabaseUrl: supabaseUrl,
        supabaseKey: supabaseKey,
        configurationStatus: configStatus,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: ${e.toString()}',
      );
    }
  }

  /// Update Kie.ai API key
  Future<bool> updateKieAiKey(String key) async {
    if (!SecureStorageService.isValidKieAiKey(key)) {
      state = state.copyWith(
        error: 'Invalid Kie.ai API key format',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.storeKieAiKey(key);
      final configStatus = await SecureStorageService.getConfigurationStatus();

      state = state.copyWith(
        kieAiKey: key,
        configurationStatus: configStatus,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save Kie.ai API key: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update Supabase credentials
  Future<bool> updateSupabaseCredentials(String url, String key) async {
    if (!SecureStorageService.isValidSupabaseUrl(url)) {
      state = state.copyWith(
        error: 'Invalid Supabase URL format',
      );
      return false;
    }

    if (!SecureStorageService.isValidSupabaseKey(key)) {
      state = state.copyWith(
        error: 'Invalid Supabase key format',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.storeSupabaseCredentials(
        url: url,
        anonKey: key,
      );
      final configStatus = await SecureStorageService.getConfigurationStatus();

      state = state.copyWith(
        supabaseUrl: url,
        supabaseKey: key,
        configurationStatus: configStatus,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save Supabase credentials: ${e.toString()}',
      );
      return false;
    }
  }

  /// Test configuration by checking if all services are accessible
  Future<Map<String, String>> testConfiguration() async {
    final results = <String, String>{};

    if (!state.isFullyConfigured) {
      results['error'] = 'Configuration is incomplete';
      return results;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Test Kie.ai API key format
      if (state.kieAiKey != null && SecureStorageService.isValidKieAiKey(state.kieAiKey)) {
        results['kie_ai'] = 'API key format is valid';
      } else {
        results['kie_ai'] = 'Invalid API key format';
      }

      // Test Supabase configuration
      if (state.supabaseUrl != null && state.supabaseKey != null) {
        if (SecureStorageService.isValidSupabaseUrl(state.supabaseUrl)) {
          results['supabase_url'] = 'URL format is valid';
        } else {
          results['supabase_url'] = 'Invalid URL format';
        }

        if (SecureStorageService.isValidSupabaseKey(state.supabaseKey)) {
          results['supabase_key'] = 'Key format is valid';
        } else {
          results['supabase_key'] = 'Invalid key format';
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: results.entries.any((e) => e.value.contains('Invalid'))
            ? 'Some configuration tests failed'
            : null,
      );
    } catch (e) {
      results['error'] = 'Configuration test failed: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }

    return results;
  }

  /// Clear all stored settings
  Future<void> clearAllSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.clearAll();

      state = const SettingsState(
        isLoading: false,
        configurationStatus: {
          'kie_ai': false,
          'supabase_url': false,
          'supabase_key': false,
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear settings: ${e.toString()}',
      );
    }
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }

  /// Reload settings from storage
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  /// Export all settings (for debugging/backup)
  Future<Map<String, String?>> exportSettings() async {
    try {
      return await SecureStorageService.exportAllData();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to export settings: ${e.toString()}',
      );
      return {};
    }
  }

  /// Check if secure storage is available
  Future<bool> isSecureStorageAvailable() async {
    return await SecureStorageService.isSecureStorageAvailable();
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

/// Convenience providers for specific settings
final kieAiKeyProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).kieAiKey;
});

final supabaseUrlProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).supabaseUrl;
});

final supabaseKeyProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).supabaseKey;
});

final isConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isFullyConfigured;
});

final configurationStatusProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(settingsProvider).configurationStatus;
});