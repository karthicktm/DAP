// webhook_endpoint_example.dart
// Example webhook endpoint for receiving kie.ai music generation callbacks
// Deploy this to your Railway/Vercel/etc backend service

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main() async {
  final app = Router();

  // Configure CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };

  // Webhook endpoint for kie.ai music generation callbacks
  app.post('/api/webhook/music', (Request request) async {
    try {
      print('🔔 Received webhook callback from kie.ai');

      // Parse the webhook payload
      final body = await request.readAsString();
      final payload = jsonDecode(body) as Map<String, dynamic>;

      print('📋 Webhook payload: $payload');

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

      if (callbackType == 'complete' && trackDataList != null && trackDataList.isNotEmpty) {
        final trackData = trackDataList[0] as Map<String, dynamic>;

        print('🎵 Track completed:');
        print('   Title: ${trackData['title']}');
        print('   Audio URL: ${trackData['audioUrl']}');
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

  // Handle CORS preflight requests
  app.options('/api/webhook/music', (Request request) {
    return Response.ok('', headers: corsHeaders);
  });

  // Start the server
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(
    Pipeline()
        .addMiddleware(corsHeaders)
        .addHandler(app),
    InternetAddress.anyIPv4,
    port,
  );

  print('🚀 Webhook server running on port $port');
  print('🔗 Webhook URL: https://your-app-domain.com/api/webhook/music');
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
    // Replace with your actual Supabase client initialization
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
    final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      print('⚠️ Supabase credentials not configured');
      return;
    }

    // Create the updated track data
    final updatedTrackData = {
      'title': trackData['title'] ?? 'AI Generated Track',
      'artist': 'AI Artist',
      'audio_url': trackData['audioUrl'] ?? '',
      'cover_art_url': trackData['imageUrl'] ?? '',
      'duration_seconds': (trackData['duration'] is num) ? trackData['duration'].toInt() : 120,
      'is_instrumental': false,
      'metadata': {
        'sunoId': trackData['id'] ?? '',
        'prompt': trackData['prompt'] ?? '',
        'model_name': trackData['model_name'] ?? 'V5',
        'tags': trackData['tags'] ?? '',
        'streamAudioUrl': trackData['streamAudioUrl'] ?? '',
        'webhookReceived': true,
        'completedAt': DateTime.now().toIso8601String(),
      },
      'is_processing': false,
      'processing_completed': true,
      'processing_status': 'Completed via webhook',
    };

    // Here you would use the Supabase Dart client to update the record
    // Example:
    // await supabase.from('tracks').update(updatedTrackData).eq('id', taskId);

    print('✅ Track data prepared for Supabase update');
    print('🔗 Audio URL: ${trackData['audioUrl']}');

  } catch (e) {
    print('❌ Error updating Supabase track: $e');
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

    // Here you would use the Supabase Dart client
    // await supabase.from('tracks').update(statusUpdate).eq('id', taskId);

    print('📱 Status updated for $taskId: $status');

  } catch (e) {
    print('❌ Error updating status: $e');
  }
}