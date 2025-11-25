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

  // Configure CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };

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
        final trackData = trackDataList[0] as Map<String, dynamic>;

        print('🎵 Track completed:');
        print('   Title: ${trackData['title']}');
        print('   Audio URL: ${trackData['audio_url'] ?? trackData['audioUrl']}');
        print('   Image URL: ${trackData['image_url'] ?? trackData['imageUrl']}');
        print('   Duration: ${trackData['duration']}');

        // Update Supabase database with completed track
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

  // Webhook monitoring endpoint for debugging
  app.get('/api/webhook/status', (Request request) {
    final stats = {
      'server_status': 'running',
      'webhook_endpoint': '/api/webhook/music',
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
    // Create the updated track data with correct field mapping
    final audioUrl = trackData['audio_url'] ?? trackData['audioUrl'] ?? '';
    final imageUrl = trackData['image_url'] ?? trackData['imageUrl'] ?? '';

    final updatedTrackData = {
      'title': trackData['title'] ?? 'AI Generated Track',
      'artist': 'AI Artist',
      'audio_url': audioUrl,
      'cover_art_url': imageUrl,
      'duration_seconds': (trackData['duration'] is num) ? trackData['duration'].toInt() : 120,
      'is_instrumental': false,
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