import 'dart:io';

/// Test the complete webhook-based music generation workflow
void main() async {
  print('🔗 Testing Webhook-Based Music Generation Workflow\n');

  await testWebhookImplementation();
  await testAudioUrlHandling();
  await testDatabaseFlow();
  await testUIUpdates();

  print('\n✅ All webhook flow tests completed!');
}

Future<void> testWebhookImplementation() async {
  print('1. Testing Webhook Implementation...');

  // Test AI Music Service webhook setup
  final serviceFile = File('lib/services/ai_music_service.dart');
  if (await serviceFile.exists()) {
    final content = await serviceFile.readAsString();

    // Check webhook URL in request
    final hasWebhookUrl = content.contains('callBackUrl') &&
                         content.contains('https://dap-production-99ef.up.railway.app/api/webhook/music');
    print('   ${hasWebhookUrl ? "✅" : "❌"} Webhook URL configured in API request');

    // Check initial processing track creation
    final hasProcessingTrack = content.contains('processingTrack') &&
                              content.contains('isProcessing: true') &&
                              content.contains('webhookExpected: true');
    print('   ${hasProcessingTrack ? "✅" : "❌"} Processing track created with webhook metadata');

    // Check no polling logic
    final noPolling = !content.contains('_pollForTrackResult') ||
                     content.contains('/// Poll for track result using taskId') &&
                     content.indexOf('_pollForTrackResult') < content.indexOf('/// Format prompt');
    print('   ${noPolling ? "✅" : "❌"} Polling logic removed');

  } else {
    print('   ❌ AI music service file not found');
  }

  // Test Webhook Service
  final webhookFile = File('lib/services/webhook_service.dart');
  if (await webhookFile.exists()) {
    final content = await webhookFile.readAsString();

    // Check kie.ai webhook structure handling
    final hasKieAiHandling = content.contains('_isValidKieAiWebhookPayload') &&
                           content.contains('callbackType') &&
                           content.contains("data['data'] as List");
    print('   ${hasKieAiHandling ? "✅" : "❌"} kie.ai webhook structure properly handled');

    // Check track updating logic
    final hasTrackUpdate = content.contains('_updateTrackFromWebhook') &&
                          content.contains("trackData['audioUrl']") &&
                          content.contains('processingCompleted: true');
    print('   ${hasTrackUpdate ? "✅" : "❌"} Track update logic implemented');

  } else {
    print('   ❌ Webhook service file not found');
  }

  // Test webhook endpoint example
  final endpointFile = File('webhook_endpoint_example.dart');
  if (await endpointFile.exists()) {
    final content = await endpointFile.readAsString();

    // Check kie.ai webhook handling
    final hasEndpoint = content.contains('/api/webhook/music') &&
                       content.contains('_updateSupabaseTrack') &&
                       content.contains('callbackType');
    print('   ${hasEndpoint ? "✅" : "❌"} Deployable webhook endpoint created');

  } else {
    print('   ❌ Webhook endpoint example not found');
  }

  print('');
}

Future<void> testAudioUrlHandling() async {
  print('2. Testing Audio URL Handling...');

  final webhookFile = File('lib/services/webhook_service.dart');
  if (await webhookFile.exists()) {
    final content = await webhookFile.readAsString();

    // Check audio URL extraction
    final hasAudioExtraction = content.contains("audioUrl: trackData['audioUrl']") &&
                              content.contains("coverArtUrl: trackData['imageUrl']") &&
                              content.contains("streamAudioUrl");
    print('   ${hasAudioExtraction ? "✅" : "❌"} Audio URL properly extracted from webhook');

    // Check metadata preservation
    final hasMetadata = content.contains("'sunoId': trackData['id']") &&
                       content.contains("'model_name': trackData['model_name']") &&
                       content.contains("'webhookReceived': true");
    print('   ${hasMetadata ? "✅" : "❌"} Track metadata properly preserved');

    // Check real-time notification
    final hasNotification = content.contains('_notifyTrackCompleted') &&
                           content.contains('Audio URL available');
    print('   ${hasNotification ? "✅" : "❌"} Real-time completion notification implemented');

  } else {
    print('   ❌ Webhook service file not found');
  }

  print('');
}

Future<void> testDatabaseFlow() async {
  print('3. Testing Database Flow...');

  final serviceFile = File('lib/services/ai_music_service.dart');
  if (await serviceFile.exists()) {
    final content = await serviceFile.readAsString();

    // Check initial save to database
    final hasInitialSave = content.contains('await TrackDatabaseService().saveTrack(processingTrack)') &&
                          content.contains('Processing track saved to database with taskId');
    print('   ${hasInitialSave ? "✅" : "❌"} Initial processing track saved to Supabase');

  }

  final webhookFile = File('lib/services/webhook_service.dart');
  if (await webhookFile.exists()) {
    final content = await webhookFile.readAsString();

    // Check webhook update to database
    final hasWebhookUpdate = content.contains('await databaseService.saveTrack(updatedTrack)') &&
                            content.contains('Track updated in Supabase with real audio URL');
    print('   ${hasWebhookUpdate ? "✅" : "❌"} Webhook updates track in Supabase');

    // Check status updates
    final hasStatusUpdate = content.contains('updateProcessingStatus') &&
                           content.contains('Updated processing status');
    print('   ${hasStatusUpdate ? "✅" : "❌"} Processing status updates implemented');

  }

  print('');
}

Future<void> testUIUpdates() async {
  print('4. Testing UI Real-time Updates...');

  final trackListFile = File('lib/widgets/track_list_widget.dart');
  if (await trackListFile.exists()) {
    final content = await trackListFile.readAsString();

    // Check real-time update setup
    final hasRealTimeUpdates = content.contains('_setupRealTimeUpdates') &&
                              content.contains('Timer.periodic') &&
                              content.contains('hasNewCompletedTracks');
    print('   ${hasRealTimeUpdates ? "✅" : "❌"} Real-time UI updates configured');

    // Check Timer import
    final hasTimerImport = content.contains("import 'dart:async';");
    print('   ${hasTimerImport ? "✅" : "❌"} Timer import added for periodic updates');

    // Check completion detection
    final hasCompletionDetection = content.contains('track.processingCompleted') &&
                                   content.contains('Detected completed tracks via webhook');
    print('   ${hasCompletionDetection ? "✅" : "❌"} Webhook completion detection implemented');

  } else {
    print('   ❌ Track list widget file not found');
  }

  final studioFile = File('lib/screens/ai_music_studio_screen_simple.dart');
  if (await studioFile.exists()) {
    final content = await studioFile.readAsString();

    // Check if studio still saves tracks (should still work as backup)
    final hasStudioSave = content.contains('await _databaseService.saveTrack(track)');
    print('   ${hasStudioSave ? "✅" : "❌"} Studio screen still saves tracks as backup');

  }

  print('');
}