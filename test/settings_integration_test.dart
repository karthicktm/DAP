import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main_updated.dart';
import '../lib/providers/settings_provider.dart';

void main() {
  group('Settings Integration Tests', () {
    testWidgets('App should start and settings navigation should work', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: UpdatedApp(),
        ),
      );

      // Wait for the app to initialize
      await tester.pump(const Duration(seconds: 1));

      // Verify that the main navigation page loads
      expect(find.text('AI Radio Platform'), findsOneWidget);

      // Verify bottom navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('AI Music'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Settings navigation should navigate to settings screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: UpdatedApp(),
        ),
      );

      // Wait for the app to initialize
      await tester.pump(const Duration(seconds: 1));

      // Find and tap the Settings tab in bottom navigation
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that we're on the settings screen (check for app bar)
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('AI Music Studio should show configuration warning when not set up', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: UpdatedApp(),
        ),
      );

      // Wait for the app to initialize
      await tester.pump(const Duration(seconds: 1));

      // Navigate to AI Music Studio
      final aiMusicTab = find.text('AI Music');
      expect(aiMusicTab, findsOneWidget);
      await tester.tap(aiMusicTab);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that setup warning is shown
      expect(find.text('Setup Required'), findsOneWidget);
    });

    testWidgets('Home page should show configuration status', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: UpdatedApp(),
        ),
      );

      // Wait for the app to initialize
      await tester.pump(const Duration(seconds: 1));

      // Verify that system status card is present
      expect(find.text('System Status'), findsOneWidget);
      expect(find.text('kie.ai Ready'), findsOneWidget);
      expect(find.text('Supabase Ready'), findsOneWidget);
    });

    testWidgets('Configure Settings button should navigate to settings', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: UpdatedApp(),
        ),
      );

      // Wait for the app to initialize
      await tester.pump(const Duration(seconds: 1));

      // Find and tap the Configure Settings button
      final configureButton = find.text('⚙️ Configure Settings');
      expect(configureButton, findsOneWidget);
      await tester.tap(configureButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify navigation to settings screen
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Settings State Management Tests', () {
    test('SettingsState should have correct initial values', () {
      const state = SettingsState();

      expect(state.kieAiKey, isNull);
      expect(state.supabaseUrl, isNull);
      expect(state.supabaseKey, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isFullyConfigured, isFalse);
      expect(state.hasError, isFalse);
    });

    test('SettingsState copyWith should work correctly', () {
      const originalState = SettingsState();

      final newState = originalState.copyWith(
        kieAiKey: 'test_key',
        isLoading: true,
      );

      expect(newState.kieAiKey, equals('test_key'));
      expect(newState.isLoading, isTrue);
      expect(newState.supabaseUrl, isNull);
      expect(newState.supabaseKey, isNull);
      expect(newState.error, isNull);
    });

    test('SettingsState isFullyConfigured should work correctly', () {
      const notConfiguredState = SettingsState();
      expect(notConfiguredState.isFullyConfigured, isFalse);

      const partiallyConfiguredState = SettingsState(
        configurationStatus: {
          'kie_ai': true,
          'supabase_url': false,
          'supabase_key': false,
        },
      );
      expect(partiallyConfiguredState.isFullyConfigured, isFalse);

      const fullyConfiguredState = SettingsState(
        configurationStatus: {
          'kie_ai': true,
          'supabase_url': true,
          'supabase_key': true,
        },
      );
      expect(fullyConfiguredState.isFullyConfigured, isTrue);
    });
  });
}