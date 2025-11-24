import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/providers/settings_provider.dart';
import '../lib/services/secure_storage_service.dart';

void main() {
  group('Settings Functionality Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('settings provider should initialize correctly', () {
      final settingsNotifier = container.read(settingsProvider.notifier);
      expect(settingsNotifier, isNotNull);
    });

    test('configuration status should be accurate', () {
      final settings = container.read(settingsProvider);
      expect(settings.configurationStatus, isA<Map<String, bool>>());
      expect(settings.configurationStatus.containsKey('kie_ai'), isTrue);
      expect(settings.configurationStatus.containsKey('supabase_url'), isTrue);
      expect(settings.configurationStatus.containsKey('supabase_key'), isTrue);
    });

    test('isFullyConfigured should return false initially', () {
      final settings = container.read(settingsProvider);
      expect(settings.isFullyConfigured, isFalse);
    });

    test('kie.ai key validation should work', () {
      expect(SecureStorageService.isValidKieAiKey(null), isFalse);
      expect(SecureStorageService.isValidKieAiKey(''), isFalse);
      expect(SecureStorageService.isValidKieAiKey('short'), isFalse);
      expect(SecureStorageService.isValidKieAiKey('valid_key_with_underscores123'), isTrue);
    });

    test('Supabase URL validation should work', () {
      expect(SecureStorageService.isValidSupabaseUrl(null), isFalse);
      expect(SecureStorageService.isValidSupabaseUrl(''), isFalse);
      expect(SecureStorageService.isValidSupabaseUrl('invalid-url'), isFalse);
      expect(SecureStorageService.isValidSupabaseUrl('https://example.com'), isFalse);
      expect(SecureStorageService.isValidSupabaseUrl('https://your-project.supabase.co'), isTrue);
      expect(SecureStorageService.isValidSupabaseUrl('https://localhost:54321'), isTrue);
    });

    test('Supabase key validation should work', () {
      expect(SecureStorageService.isValidSupabaseKey(null), isFalse);
      expect(SecureStorageService.isValidSupabaseKey(''), isFalse);
      expect(SecureStorageService.isValidSupabaseKey('short'), isFalse);
      expect(SecureStorageService.isValidSupabaseKey('valid_long_supabase_key_1234567890'), isTrue);
    });

    test('settings state should copy correctly', () {
      const originalState = SettingsState(
        kieAiKey: 'test_key',
        supabaseUrl: 'https://test.supabase.co',
        supabaseKey: 'test_supabase_key',
        isLoading: false,
      );

      final newState = originalState.copyWith(
        kieAiKey: 'new_test_key',
        isLoading: true,
      );

      expect(newState.kieAiKey, equals('new_test_key'));
      expect(newState.supabaseUrl, equals('https://test.supabase.co'));
      expect(newState.supabaseKey, equals('test_supabase_key'));
      expect(newState.isLoading, isTrue);
    });

    test('providers should return correct values', () {
      final kieAiKey = container.read(kieAiKeyProvider);
      final supabaseUrl = container.read(supabaseUrlProvider);
      final supabaseKey = container.read(supabaseKeyProvider);
      final isConfigured = container.read(isConfiguredProvider);
      final configStatus = container.read(configurationStatusProvider);

      expect(kieAiKey, isA<String?>());
      expect(supabaseUrl, isA<String?>());
      expect(supabaseKey, isA<String?>());
      expect(isConfigured, isA<bool>());
      expect(configStatus, isA<Map<String, bool>>());
    });
  });
}