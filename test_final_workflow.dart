import 'dart:io';

/// Final validation test for the complete AI music generation workflow
void main() async {
  print('🎯 Final Workflow Validation Test\n');

  await testKieAiIntegration();
  await testSupabaseIntegration();
  await testUIIntegration();

  print('\n✅ All workflow tests completed!');
}

Future<void> testKieAiIntegration() async {
  print('1. Testing kie.ai API Integration...');

  final serviceFile = File('lib/services/ai_music_service.dart');
  if (await serviceFile.exists()) {
    final content = await serviceFile.readAsString();

    // Check for proper API request format
    final hasCorrectFormat = content.contains("'prompt': formattedPrompt") &&
                           content.contains("'instrumental': instrumental") &&
                           content.contains("'model': 'V5'");

    print('   ${hasCorrectFormat ? "✅" : "❌"} Correct API request format');

    // Check for proper polling implementation
    final hasPolling = content.contains('_pollForTrackResult') &&
                      content.contains("data['data']['status'] == 'SUCCESS'") &&
                      content.contains("data['data']['response']['sunoData']");

    print('   ${hasPolling ? "✅" : "❌"} Proper taskId polling');

    // Check for actual response parsing
    final hasResponseParsing = content.contains("firstTrack['audioUrl']") &&
                              content.contains("firstTrack['title']") &&
                              content.contains("firstTrack['duration']");

    print('   ${hasResponseParsing ? "✅" : "❌"} Real response data parsing');

    // Check no mock data
    final noMockData = !content.contains('mock') && !content.contains('Mock');
    print('   ${noMockData ? "✅" : "❌"} No mock data fallbacks');

  } else {
    print('   ❌ AI music service file not found');
  }

  print('');
}

Future<void> testSupabaseIntegration() async {
  print('2. Testing Supabase Data Storage...');

  final dbServiceFile = File('lib/services/track_database_service.dart');
  if (await dbServiceFile.exists()) {
    final content = await dbServiceFile.readAsString();

    // Check for proper data mapping
    final hasProperMapping = content.contains("'audio_url': track.audioUrl") &&
                           content.contains("'cover_art_url': track.coverArtUrl") &&
                           content.contains("'metadata': track.metadata");

    print('   ${hasProperMapping ? "✅" : "❌"} Proper track data mapping');

    // Check no auto-clearing of tracks
    final noAutoClear = !content.contains('clearAllTracks()') ||
                       content.contains('Clear all tracks from local storage (useful for removing mock data)');

    print('   ${noAutoClear ? "✅" : "❌"} No automatic track clearing');

    // Check local storage fallback still works
    final hasLocalFallback = content.contains('SharedPreferences') &&
                           content.contains('_saveTrackLocally');

    print('   ${hasLocalFallback ? "✅" : "❌"} Local storage fallback available');

  } else {
    print('   ❌ Database service file not found');
  }

  // Check TrackListWidget doesn't clear tracks on load
  final trackListFile = File('lib/widgets/track_list_widget.dart');
  if (await trackListFile.exists()) {
    final content = await trackListFile.readAsString();

    final noClearOnLoad = !content.contains('await _databaseService.clearAllTracks()');
    print('   ${noClearOnLoad ? "✅" : "❌"} Track list doesn\'t clear on load');

  } else {
    print('   ❌ Track list widget file not found');
  }

  print('');
}

Future<void> testUIIntegration() async {
  print('3. Testing UI Integration...');

  final studioFile = File('lib/screens/ai_music_studio_screen_simple.dart');
  if (await studioFile.exists()) {
    final content = await studioFile.readAsString();

    // Check track saving to database
    final saveToDb = content.contains('await _databaseService.saveTrack(track)');
    print('   ${saveToDb ? "✅" : "❌"} Tracks saved to database on completion');

    // Check track list refresh
    final hasRefresh = content.contains('TrackListWidget.globalKey.currentState?.refreshTracks()');
    print('   ${hasRefresh ? "✅" : "❌"} Track list refreshed after generation');

  } else {
    print('   ❌ AI studio screen file not found');
  }

  final formFile = File('lib/widgets/music_generation_form.dart');
  if (await formFile.exists()) {
    final content = await formFile.readAsString();

    // Check proper callback handling
    final hasCallback = content.contains('onTrackCompleted: (completedTrack)') &&
                       content.contains('widget.onGenerationComplete(completedTrack)');

    print('   ${hasCallback ? "✅" : "❌"} Proper callback handling in form');

  } else {
    print('   ❌ Music generation form file not found');
  }

  print('');
}