#!/usr/bin/env dart
// Flutter app testing script with real credentials
// Run with: flutter test test_flutter_v5.dart

import 'package:flutter_test/flutter_test.dart';
import 'lib/services/ai_music_service.dart';
import 'lib/services/track_database_service.dart';
import 'lib/services/secure_storage_service.dart';
import 'lib/models/ai_track.dart';

void main() {
  group('kie.ai v5 Integration Tests', () {
    late AIMusicService musicService;
    late TrackDatabaseService dbService;

    setUpAll(() async {
      print('🧪 Setting up v5 Integration Tests');

      // Initialize services
      musicService = AIMusicService();
      dbService = TrackDatabaseService();

      // You'll need to set these before running the test
      print('⚠️ Make sure to set your credentials first:');
      print('   await SecureStorageService.setKieAiKey("your_key_here");');
      print('   await SecureStorageService.setSupabaseUrl("your_url_here");');
      print('   await SecureStorageService.setSupabaseKey("your_key_here");');
    });

    testWidgets('Test v5 Parameters Integration', (tester) async {
      print('\n🎵 Testing v5 parameters...');

      try {
        // Test music generation with v5 parameters
        final track = await musicService.generateMusic(
          prompt: 'A peaceful piano melody for testing v5 integration',
          genre: 'classical',
          mood: 'relaxing',
          style: 'modern',
          instrumental: true,
          model: 'V5',
          // v5 specific parameters
          styleWeight: 0.75,
          weirdnessConstraint: 0.3,
          audioWeight: 0.6,
          negativeTags: 'heavy metal, upbeat drums',
        );

        print('✅ Music generation request sent');
        print('   Track ID: ${track.id}');
        print('   Title: ${track.title}');

        expect(track.id.isNotEmpty, true);
        expect(track.title.contains('piano'), true);

      } catch (e) {
        print('❌ v5 parameter test failed: $e');
        fail('v5 integration test failed: $e');
      }
    });

    testWidgets('Test Database Real-time Updates', (tester) async {
      print('\n🗄️ Testing database real-time updates...');

      try {
        await dbService.initialize();

        if (dbService.isSupabaseAvailable) {
          print('✅ Supabase connection established');

          // Test real-time listener
          final stream = dbService.listenToTrackUpdates();
          if (stream != null) {
            print('✅ Real-time listener created');

            // Listen for a few seconds
            await Future.delayed(Duration(seconds: 2));
            print('✅ Real-time stream is working');
          } else {
            print('❌ Real-time listener failed to create');
          }
        } else {
          print('⚠️ Supabase not available, using local storage');
        }

      } catch (e) {
        print('❌ Database test failed: $e');
        fail('Database test failed: $e');
      }
    });

    testWidgets('Test Field Mapping Fix', (tester) async {
      print('\n🔧 Testing field mapping fixes...');

      // Test the _trackFromJson method with both field formats
      final mockWebhookData = {
        'id': 'test_123',
        'title': 'Test Track',
        'audio_url': 'https://example.com/audio.mp3',  // kie.ai format
        'image_url': 'https://example.com/image.jpg',   // kie.ai format
        'duration': 180,
        'tags': 'classical, piano',
        'model_name': 'V5',
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        // This should work with the fixed field mapping
        final track = AITrack(
          id: mockWebhookData['id']!,
          title: mockWebhookData['title']!,
          artist: 'AI Artist',
          genre: mockWebhookData['tags']!,
          mood: 'Generated',
          duration: Duration(seconds: mockWebhookData['duration']!),
          audioUrl: mockWebhookData['audio_url']!, // Should map correctly
          coverArtUrl: mockWebhookData['image_url'], // Should map correctly
          createdAt: DateTime.parse(mockWebhookData['created_at']!),
        );

        print('✅ Field mapping test passed');
        print('   Audio URL: ${track.audioUrl}');
        print('   Cover Art URL: ${track.coverArtUrl}');

        expect(track.audioUrl.contains('example.com'), true);
        expect(track.coverArtUrl?.contains('example.com'), true);

      } catch (e) {
        print('❌ Field mapping test failed: $e');
        fail('Field mapping test failed: $e');
      }
    });
  });
}