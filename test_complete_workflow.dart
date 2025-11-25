import 'dart:io';
import 'dart:convert';

/// Comprehensive workflow test for the AI music generation app
void main() async {
  print('🔍 Testing Complete AI Music App Workflow...\n');

  // Test 1: Validate app structure and dependencies
  await testAppStructure();

  // Test 2: Test environment configuration
  await testEnvironmentConfiguration();

  // Test 3: Test database service capabilities
  await testDatabaseService();

  // Test 4: Test music generation service
  await testMusicGenerationService();

  print('\n✅ Complete workflow testing completed!');
}

Future<void> testAppStructure() async {
  print('1. Testing App Structure & Dependencies...');

  // Check essential files exist
  final requiredFiles = [
    'lib/main.dart',
    'lib/main_updated.dart',
    'lib/screens/ai_music_studio_screen_simple.dart',
    'lib/services/ai_music_service.dart',
    'lib/services/track_database_service.dart',
    'lib/widgets/music_generation_form.dart',
    'lib/widgets/track_list_widget.dart',
    'lib/models/ai_track.dart',
    'pubspec.yaml',
    '.env'
  ];

  for (String filePath in requiredFiles) {
    if (await File(filePath).exists()) {
      print('   ✅ $filePath');
    } else {
      print('   ❌ Missing: $filePath');
    }
  }

  // Check pubspec dependencies
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final pubspec = await pubspecFile.readAsString();
    final requiredDeps = [
      'flutter_riverpod:',
      'supabase_flutter:',
      'just_audio:',
      'shared_preferences:',
      'dio:',
      'flutter_secure_storage:'
    ];

    for (String dep in requiredDeps) {
      if (pubspec.contains(dep)) {
        print('   ✅ Dependency: $dep');
      } else {
        print('   ❌ Missing dependency: $dep');
      }
    }
  }

  print('');
}

Future<void> testEnvironmentConfiguration() async {
  print('2. Testing Environment Configuration...');

  final envFile = File('.env');
  if (await envFile.exists()) {
    final envContent = await envFile.readAsString();

    // Check required environment variables
    final envVars = [
      'KIE_AI_API_KEY',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY'
    ];

    for (String envVar in envVars) {
      if (envContent.contains(envVar)) {
        final isConfigured = !envContent.contains('${envVar}=your_');
        print('   ${isConfigured ? "✅" : "⚠️"} $envVar: ${isConfigured ? "Configured" : "Needs setup"}');
      } else {
        print('   ❌ Missing: $envVar');
      }
    }
  } else {
    print('   ❌ .env file not found');
  }

  print('');
}

Future<void> testDatabaseService() async {
  print('3. Testing Database Service Implementation...');

  final dbServiceFile = File('lib/services/track_database_service.dart');
  if (await dbServiceFile.exists()) {
    final content = await dbServiceFile.readAsString();

    // Check for required methods
    final requiredMethods = [
      'initialize()',
      'saveTrack(',
      'getAllTracks()',
      'deleteTrack(',
      'addProcessingTrack(',
      'updateProcessingStatus(',
      'completeProcessingTrack('
    ];

    for (String method in requiredMethods) {
      if (content.contains(method)) {
        print('   ✅ Method: $method');
      } else {
        print('   ❌ Missing method: $method');
      }
    }

    // Check for Supabase integration
    if (content.contains('SupabaseClient')) {
      print('   ✅ Supabase client integration');
    } else {
      print('   ❌ Missing Supabase client integration');
    }

    // Check for local storage fallback
    if (content.contains('SharedPreferences')) {
      print('   ✅ Local storage fallback');
    } else {
      print('   ❌ Missing local storage fallback');
    }

  } else {
    print('   ❌ Database service file not found');
  }

  print('');
}

Future<void> testMusicGenerationService() async {
  print('4. Testing Music Generation Service...');

  final musicServiceFile = File('lib/services/ai_music_service.dart');
  if (await musicServiceFile.exists()) {
    final content = await musicServiceFile.readAsString();

    // Check for required functionality
    final requiredFeatures = [
      'generateMusic(',
      'Dio',
      'kie.ai',
      '_createMockTrack',
      'ApiConstants',
      'SecureStorageService'
    ];

    for (String feature in requiredFeatures) {
      if (content.contains(feature)) {
        print('   ✅ Feature: $feature');
      } else {
        print('   ❌ Missing feature: $feature');
      }
    }

    // Check AI Music Studio integration
    final studioFile = File('lib/screens/ai_music_studio_screen_simple.dart');
    if (await studioFile.exists()) {
      final studioContent = await studioFile.readAsString();

      // Check integration points
      final integrations = [
        'AIMusicService',
        'TrackDatabaseService',
        'MusicGenerationForm',
        'TrackListWidget',
        'refreshTracks()'
      ];

      for (String integration in integrations) {
        if (studioContent.contains(integration)) {
          print('   ✅ Studio integration: $integration');
        } else {
          print('   ❌ Missing studio integration: $integration');
        }
      }
    }

  } else {
    print('   ❌ Music service file not found');
  }

  // Test TrackListWidget refresh functionality
  final trackListFile = File('lib/widgets/track_list_widget.dart');
  if (await trackListFile.exists()) {
    final content = await trackListFile.readAsString();

    if (content.contains('GlobalKey') && content.contains('refreshTracks()')) {
      print('   ✅ TrackListWidget refresh functionality');
    } else {
      print('   ❌ Missing TrackListWidget refresh functionality');
    }
  }

  print('');
}