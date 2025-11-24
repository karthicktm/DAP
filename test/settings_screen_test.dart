import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/settings_screen.dart';
import '../lib/providers/settings_provider.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('SettingsScreen should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Verify that the app bar with "Settings" title is present
      expect(find.text('Settings'), findsOneWidget);

      // Verify that key sections are present
      expect(find.text('Configuration Status'), findsOneWidget);
      expect(find.text('API Configuration'), findsOneWidget);
      expect(find.text('Quick Setup'), findsOneWidget);
    });

    testWidgets('SettingsScreen should display configuration tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Wait for the widget to fully load
      await tester.pumpAndSettle();

      // Verify that API configuration tiles are present
      expect(find.text('Kie.ai API Key'), findsOneWidget);
      expect(find.text('Supabase Configuration'), findsOneWidget);
      expect(find.text('Not configured'), findsAtLeastNWidgets(2));
    });

    testWidgets('SettingsScreen should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) {
              return SettingsNotifier();
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading settings...'), findsOneWidget);
    });

    testWidgets('Quick Setup button should be present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Quick Setup button
      expect(find.text('Quick Setup'), findsOneWidget);
    });

    testWidgets('Setup Instructions button should be present when not configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Setup Instructions button
      expect(find.text('Setup Instructions'), findsOneWidget);
    });
  });
}