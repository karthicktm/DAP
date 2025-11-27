// bin/webhook_server.dart
// Production webhook server for receiving kie.ai music generation callbacks
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;
import 'package:supabase/supabase.dart';

late SupabaseClient supabase;

// Configure CORS headers globally
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

void main() async {
  // Initialize Supabase client
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('❌ Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.');
    exit(1);
  }

  supabase = SupabaseClient(supabaseUrl, supabaseKey);
  print('✅ Supabase client initialized');

  final app = Router();

  // Webhook endpoint for kie.ai music generation callbacks
  app.post('/api/webhook/music', (Request request) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      print('🔔 [$timestamp] Received webhook callback from kie.ai');
      print('📍 Request headers: ${request.headers}');
      print('📍 Request URL: ${request.requestedUri}');

      // Parse the webhook payload
      final body = await request.readAsString();
      print('📄 Raw webhook body: $body');

      if (body.isEmpty) {
        print('❌ Empty webhook body received');
        return Response.badRequest(body: 'Empty payload');
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      print('📋 [$timestamp] Parsed webhook payload: $payload');

      // Validate the kie.ai webhook structure
      if (!_isValidKieAiWebhook(payload)) {
        print('❌ Invalid webhook payload structure');
        return Response.badRequest(body: 'Invalid payload structure');
      }

      final code = payload['code'] as int;
      final data = payload['data'] as Map<String, dynamic>;

      if (code != 200) {
        print('❌ Webhook error code: $code');
        return Response.ok('Webhook received with error');
      }

      final callbackType = data['callbackType'] as String?;
      final taskId = data['task_id'] as String? ?? data['taskId'] as String?;
      final trackDataList = data['data'] as List?;

      print('📋 Callback details: type=$callbackType, taskId=$taskId');

      if (taskId == null) {
        print('❌ No taskId found in webhook payload');
        return Response.badRequest(body: 'Missing taskId in payload');
      }

      if (callbackType == 'complete' && trackDataList != null && trackDataList.isNotEmpty) {
        print('🎵 Multiple tracks received: ${trackDataList.length}');

        // Log all tracks to understand what we're getting
        for (int i = 0; i < trackDataList.length; i++) {
          final track = trackDataList[i] as Map<String, dynamic>;
          print('   Track ${i + 1}: ${track['title']} - Duration: ${track['duration']}s');
          print('   Audio URL: ${track['audio_url'] ?? track['audioUrl']}');
        }

        // DISABLED: Save all track alternatives to prevent duplicates
        // await _saveAllTrackAlternativesWebhook(taskId, trackDataList);

        // Select the first track as the primary (default behavior)
        final trackData = trackDataList[0] as Map<String, dynamic>;

        print('🎵 Selected primary track (first):');
        print('   Title: ${trackData['title']}');
        print('   Audio URL: ${trackData['audio_url'] ?? trackData['audioUrl']}');
        print('   Image URL: ${trackData['image_url'] ?? trackData['imageUrl']}');
        print('   Duration: ${trackData['duration']}');

        // Update Supabase database with completed primary track
        await _updateSupabaseTrack(taskId, trackData);

      } else if (callbackType == 'first') {
        print('🎵 First track completed, more tracks coming...');
        await _updateSupabaseStatus(taskId, 'First track completed');

      } else if (callbackType == 'text') {
        print('📝 Text generation completed');
        await _updateSupabaseStatus(taskId, 'Text generated, creating audio...');
      }

      // Respond to kie.ai to acknowledge receipt
      return Response.ok(
        jsonEncode({'status': 'received', 'message': 'Webhook processed successfully'}),
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      );

    } catch (e) {
      print('❌ Error processing webhook: $e');
      return Response.internalServerError(
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
      );
    }
  });

  // Health check endpoint
  app.get('/health', (Request request) {
    return Response.ok('Webhook service is healthy');
  });

  // Migration endpoints for fixing existing tracks
  app.get('/api/migrate/tracks', _runTrackMigration);
  app.get('/api/migrate/status', _getMigrationStatus);

  // Webhook monitoring endpoint for debugging
  app.get('/api/webhook/status', (Request request) {
    final stats = {
      'server_status': 'running',
      'webhook_endpoint': '/api/webhook/music',
      'migration_endpoint': '/api/migrate/tracks',
      'timestamp': DateTime.now().toIso8601String(),
      'supabase_connected': true, // supabase client is initialized
    };

    return Response.ok(
      jsonEncode(stats),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    );
  });

  // Handle CORS preflight requests
  app.options('/api/webhook/music', (Request request) {
    return Response.ok('', headers: corsHeaders);
  });

  // Start the server
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(
    Pipeline()
        .addMiddleware(cors.corsHeaders())
        .addHandler(app),
    InternetAddress.anyIPv4,
    port,
  );

  print('🚀 Webhook server running on port $port');
  print('🔗 Webhook URL: https://dap-production-99ef.up.railway.app/api/webhook/music');
}

/// Validate kie.ai webhook payload structure
bool _isValidKieAiWebhook(Map<String, dynamic> payload) {
  return payload.containsKey('code') &&
         payload.containsKey('data') &&
         payload['data'] is Map<String, dynamic>;
}

/// Update Supabase track with completed data
Future<void> _updateSupabaseTrack(String taskId, Map<String, dynamic> trackData) async {
  try {
    // Only update completion-related fields, preserve original track metadata
    final audioUrl = trackData['audio_url'] ?? trackData['audioUrl'] ?? '';
    final imageUrl = trackData['image_url'] ?? trackData['imageUrl'] ?? '';

    final updatedTrackData = {
      'audio_url': audioUrl,
      'cover_art_url': imageUrl,
      'duration_seconds': (trackData['duration'] is num) ? trackData['duration'].toInt() : 120,
      'metadata': {
        'sunoId': trackData['id'] ?? '',
        'prompt': trackData['prompt'] ?? '',
        'model_name': trackData['model_name'] ?? 'V5',
        'tags': trackData['tags'] ?? '',
        'streamAudioUrl': trackData['stream_audio_url'] ?? trackData['streamAudioUrl'] ?? '',
        'webhookReceived': true,
        'completedAt': DateTime.now().toIso8601String(),
        'originalTaskId': taskId,
      },
      'is_processing': false,
      'processing_completed': true,
      'processing_status': 'Completed via webhook',
      'updated_at': DateTime.now().toIso8601String(),
    };

    print('🔄 Attempting to update track with taskId: $taskId');
    print('🎵 Audio URL from webhook: $audioUrl');
    print('🖼️ Image URL from webhook: $imageUrl');

    // Try to update using taskId first (most likely scenario)
    final updateResponse = await supabase
        .from('tracks')
        .update(updatedTrackData)
        .eq('id', taskId)
        .select();

    if (updateResponse.isNotEmpty) {
      print('✅ Track updated successfully using taskId as primary key');
    } else {
      print('⚠️ No track found with id=$taskId, trying metadata.taskId...');

      // Fallback: Try to find track by taskId in metadata
      final metadataUpdateResponse = await supabase
          .from('tracks')
          .update(updatedTrackData)
          .eq('metadata->>taskId', taskId)
          .select();

      if (metadataUpdateResponse.isNotEmpty) {
        print('✅ Track updated successfully using metadata.taskId');
      } else {
        print('❌ No track found with taskId: $taskId in any field');

        // Last resort: Create new track with taskId
        final newTrackData = {
          'id': taskId,
          ...updatedTrackData,
        };

        final insertResponse = await supabase
            .from('tracks')
            .insert(newTrackData)
            .select();

        if (insertResponse.isNotEmpty) {
          print('✅ Created new track with taskId: $taskId');
        } else {
          print('❌ Failed to create new track');
        }
      }
    }

    print('✅ Webhook processing completed for taskId: $taskId');

  } catch (e) {
    print('❌ Error updating Supabase track: $e');
    print('🔍 Error details: ${e.runtimeType}');

    // Try to log more specific error information
    if (e.toString().contains('duplicate key') || e.toString().contains('already exists')) {
      print('💡 Suggestion: Track with this ID might already exist');
    } else if (e.toString().contains('not found') || e.toString().contains('no rows')) {
      print('💡 Suggestion: Track with taskId $taskId was not found in database');
    } else if (e.toString().contains('connection') || e.toString().contains('network')) {
      print('💡 Suggestion: Database connection issue - check Supabase configuration');
    }
  }
}

/// Update processing status in Supabase
Future<void> _updateSupabaseStatus(String taskId, String status) async {
  try {
    // Update only the processing status
    final statusUpdate = {
      'processing_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    print('📱 Updating status for taskId: $taskId to: $status');

    // Try to update using taskId first
    final updateResponse = await supabase
        .from('tracks')
        .update(statusUpdate)
        .eq('id', taskId)
        .select();

    if (updateResponse.isNotEmpty) {
      print('✅ Status updated successfully using taskId as primary key');
    } else {
      print('⚠️ No track found with id=$taskId, trying metadata.taskId...');

      // Fallback: Try to find track by taskId in metadata
      final metadataUpdateResponse = await supabase
          .from('tracks')
          .update(statusUpdate)
          .eq('metadata->>taskId', taskId)
          .select();

      if (metadataUpdateResponse.isNotEmpty) {
        print('✅ Status updated successfully using metadata.taskId');
      } else {
        print('❌ No track found with taskId: $taskId for status update');
      }
    }

  } catch (e) {
    print('❌ Error updating status for taskId $taskId: $e');
    print('🔍 Status update error details: ${e.runtimeType}');
  }
}

/// Save all track alternatives from webhook to allow user choice
Future<void> _saveAllTrackAlternativesWebhook(String baseTaskId, List trackDataList) async {
  try {
    print('💾 Saving ${trackDataList.length} track alternatives for taskId: $baseTaskId');

    for (int i = 0; i < trackDataList.length; i++) {
      final track = trackDataList[i] as Map<String, dynamic>;
      final isDefault = i == 0; // First track is default

      // Create unique ID for each alternative
      final trackId = isDefault ? baseTaskId : '${baseTaskId}_alt_${i + 1}';

      final audioUrl = track['audio_url'] ?? track['audioUrl'] ?? '';
      final imageUrl = track['image_url'] ?? track['imageUrl'] ?? '';
      final actualTitle = track['title'] ?? 'AI Generated Track ${i + 1}';
      final duration = (track['duration'] is num) ? track['duration'].toInt() : 120;

      print('   Track ${i + 1}: $actualTitle');
      print('   Audio URL: $audioUrl');
      print('   Duration: ${duration}s');
      print('   Track ID: $trackId');

      final alternativeTrackData = {
        'title': actualTitle,
        'artist': 'AI Artist',
        'audio_url': audioUrl,
        'cover_art_url': imageUrl,
        'duration_seconds': duration,
        'is_instrumental': false,
        'metadata': {
          'sunoId': track['id'] ?? '',
          'prompt': track['prompt'] ?? '',
          'model_name': track['model_name'] ?? 'V5',
          'tags': track['tags'] ?? '',
          'streamAudioUrl': track['stream_audio_url'] ?? track['streamAudioUrl'] ?? '',
          'webhookReceived': true,
          'completedAt': DateTime.now().toIso8601String(),
          'originalTaskId': baseTaskId,
          'alternativeIndex': i + 1,
          'isDefault': isDefault,
          'actualDuration': track['duration'],
        },
        'is_processing': false,
        'processing_completed': true,
        'processing_status': 'Completed via webhook - Alternative ${i + 1}',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert each alternative track into Supabase
      final response = await supabase
          .from('tracks')
          .upsert(alternativeTrackData..['id'] = trackId)
          .select();

      if (response.isNotEmpty) {
        print('✅ Saved alternative track ${i + 1}: $actualTitle');
      } else {
        print('⚠️ Failed to save alternative track ${i + 1}');
      }
    }

    print('🎵 All track alternatives saved for taskId: $baseTaskId');

  } catch (e) {
    print('❌ Error saving track alternatives: $e');
    print('🔍 Alternative save error details: ${e.runtimeType}');
  }
}

/// Migration endpoint to fix existing tracks with corrupted metadata
Future<Response> _runTrackMigration(Request request) async {
  try {
    print('🔧 Starting track metadata migration...');

    final response = await supabase
        .from('tracks')
        .select('*')
        .order('created_at', ascending: false);

    final tracks = response as List<dynamic>;
    print('📊 Found ${tracks.length} tracks to analyze');

    int fixedCount = 0;
    int skippedCount = 0;
    List<Map<String, dynamic>> results = [];

    for (final track in tracks) {
      final id = track['id'];
      final title = track['title'];
      final artist = track['artist'];
      final audioUrl = track['audio_url'];
      final metadata = (track['metadata'] as Map<String, dynamic>?) ?? {};

      bool needsFixing = false;
      Map<String, dynamic> updates = {};
      List<String> fixes = [];

      // Check if this track has generic/corrupted metadata
      if (title == 'AI Generated Track' ||
          title?.toString().startsWith('Generating:') == true ||
          artist == 'AI Artist' ||
          artist == 'AI Music Generator') {

        needsFixing = true;
        fixes.add('corrupted_metadata');

        final originalDescription = metadata['originalDescription'] as String?;
        final musicPrompt = metadata['musicPrompt'] as String?;
        final requestedGenre = metadata['requestedGenre'] as String?;
        final requestedMood = metadata['requestedMood'] as String?;

        String newTitle = 'Restored Track';
        String newArtist = 'AI Generated';

        if (originalDescription != null && originalDescription.isNotEmpty) {
          newTitle = originalDescription.length > 50
              ? originalDescription.substring(0, 47) + '...'
              : originalDescription;
        } else if (musicPrompt != null && musicPrompt.isNotEmpty) {
          final cleanPrompt = musicPrompt
              .replaceAll(RegExp(r'Create a \d+ second'), '')
              .replaceAll(RegExp(r'Duration: \d+ seconds'), '')
              .replaceAll(RegExp(r'Language: \w+'), '')
              .trim();

          if (cleanPrompt.isNotEmpty) {
            newTitle = cleanPrompt.length > 50
                ? cleanPrompt.substring(0, 47) + '...'
                : cleanPrompt;
          }
        }

        if (requestedGenre != null && requestedMood != null) {
          newArtist = '$requestedGenre AI · $requestedMood';
        } else if (requestedGenre != null) {
          newArtist = '$requestedGenre AI Artist';
        }

        updates['title'] = newTitle;
        updates['artist'] = newArtist;
      }

      // Check for missing audio URL
      if (audioUrl == null || audioUrl.toString().isEmpty) {
        needsFixing = true;
        fixes.add('missing_audio_url');

        final streamAudioUrl = metadata['streamAudioUrl'] as String?;
        if (streamAudioUrl != null && streamAudioUrl.isNotEmpty) {
          updates['audio_url'] = streamAudioUrl;
          fixes.add('restored_audio_url');
        }
      }

      // Apply fixes
      if (needsFixing && updates.isNotEmpty) {
        try {
          await supabase
              .from('tracks')
              .update(updates)
              .eq('id', id);

          fixedCount++;
          results.add({
            'id': id,
            'status': 'fixed',
            'fixes': fixes,
            'old_title': title,
            'new_title': updates['title'],
            'old_artist': artist,
            'new_artist': updates['artist'],
          });
        } catch (e) {
          results.add({
            'id': id,
            'status': 'error',
            'error': e.toString(),
          });
        }
      } else {
        skippedCount++;
      }
    }

    final migrationResult = {
      'success': true,
      'message': 'Track migration completed successfully',
      'stats': {
        'total_tracks': tracks.length,
        'fixed_count': fixedCount,
        'skipped_count': skippedCount,
      },
      'sample_fixes': results.where((r) => r['status'] == 'fixed').take(5).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('🎉 Migration completed: $fixedCount fixed, $skippedCount skipped');

    return Response.ok(
      jsonEncode(migrationResult),
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    );

  } catch (e) {
    print('❌ Migration error: $e');
    return Response.internalServerError(
      body: jsonEncode({
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

/// Get migration status and database statistics
Future<Response> _getMigrationStatus(Request request) async {
  try {
    final response = await supabase
        .from('tracks')
        .select('id, title, artist, audio_url')
        .order('created_at', ascending: false);

    final tracks = response as List<dynamic>;

    int corruptedTracks = 0;
    int missingAudioUrls = 0;
    int healthyTracks = 0;

    for (final track in tracks) {
      final title = track['title'];
      final artist = track['artist'];
      final audioUrl = track['audio_url'];

      bool isCorrupted = false;

      if (title == 'AI Generated Track' ||
          title?.toString().startsWith('Generating:') == true ||
          artist == 'AI Artist' ||
          artist == 'AI Music Generator') {
        corruptedTracks++;
        isCorrupted = true;
      }

      if (audioUrl == null || audioUrl.toString().isEmpty) {
        missingAudioUrls++;
        isCorrupted = true;
      }

      if (!isCorrupted) {
        healthyTracks++;
      }
    }

    final status = {
      'database_stats': {
        'total_tracks': tracks.length,
        'healthy_tracks': healthyTracks,
        'corrupted_metadata': corruptedTracks,
        'missing_audio_urls': missingAudioUrls,
      },
      'migration_needed': corruptedTracks > 0 || missingAudioUrls > 0,
      'migration_url': '/api/migrate/tracks',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response.ok(
      jsonEncode(status),
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    );

  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}