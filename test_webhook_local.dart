#!/usr/bin/env dart
// Local webhook server for testing kie.ai callbacks
// Run with: dart test_webhook_local.dart

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  print('🌐 Starting Local Webhook Server for kie.ai Testing');
  print('=' * 60);

  final app = Router();

  // Webhook endpoint that matches the production path
  app.post('/api/webhook/music', (Request request) async {
    try {
      print('\n🔔 Webhook callback received at ${DateTime.now()}');
      print('-' * 40);

      // Parse the webhook payload
      final body = await request.readAsString();
      final payload = jsonDecode(body) as Map<String, dynamic>;

      print('📋 Raw Payload:');
      print(jsonEncode(payload));
      print('');

      // Validate the kie.ai webhook structure
      if (!_isValidKieAiWebhook(payload)) {
        print('❌ Invalid webhook payload structure');
        return Response.badRequest(body: 'Invalid payload structure');
      }

      final code = payload['code'] as int;
      final data = payload['data'] as Map<String, dynamic>;
      final callbackType = data['callbackType'] as String?;
      final taskId = data['task_id'] as String? ?? data['taskId'] as String?;

      print('📊 Webhook Summary:');
      print('   Status Code: $code');
      print('   Callback Type: $callbackType');
      print('   Task ID: $taskId');

      if (code != 200) {
        print('❌ Webhook error code: $code');
        print('   Message: ${payload['msg']}');
        return Response.ok('Webhook received with error');
      }

      // Handle different callback types
      switch (callbackType) {
        case 'text':
          print('📝 Text generation completed');
          print('   Next: Audio generation starting...');
          break;

        case 'first':
          print('🎵 First track completed');
          final trackDataList = data['data'] as List?;
          if (trackDataList != null && trackDataList.isNotEmpty) {
            final firstTrack = trackDataList[0] as Map<String, dynamic>;
            print('   Title: ${firstTrack['title']}');
            print('   Partial Audio URL: ${firstTrack['audio_url'] ?? firstTrack['audioUrl']}');
          }
          print('   Next: Generating remaining tracks...');
          break;

        case 'complete':
          print('✅ All tracks completed!');
          final trackDataList = data['data'] as List?;
          if (trackDataList != null && trackDataList.isNotEmpty) {
            print('   Generated ${trackDataList.length} track(s):');
            for (int i = 0; i < trackDataList.length; i++) {
              final track = trackDataList[i] as Map<String, dynamic>;
              print('   Track ${i + 1}:');
              print('     Title: ${track['title']}');
              print('     Audio URL: ${track['audio_url'] ?? track['audioUrl']}');
              print('     Image URL: ${track['image_url'] ?? track['imageUrl']}');
              print('     Duration: ${track['duration']}s');
              print('     Model: ${track['model_name']}');
              print('     Tags: ${track['tags']}');
            }
          }
          print('🎉 Music generation fully complete!');
          break;

        case 'error':
          print('💥 Generation failed');
          print('   Task ID: $taskId');
          break;

        default:
          print('⚠️ Unknown callback type: $callbackType');
      }

      print('-' * 40);

      // Return success response to kie.ai
      return Response.ok(
        jsonEncode({'status': 'received', 'message': 'Webhook processed successfully'}),
        headers: {
          'Content-Type': 'application/json',
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
    return Response.ok('Local webhook server is healthy');
  });

  // Root endpoint with info
  app.get('/', (Request request) {
    return Response.ok('''
🌐 Local kie.ai Webhook Test Server

Endpoints:
- POST /api/webhook/music - Webhook callback handler
- GET /health - Health check
- GET / - This info page

Server is running and ready to receive kie.ai callbacks!
    ''');
  });

  // Start the server
  const port = 8080;
  final server = await io.serve(app, InternetAddress.anyIPv4, port);

  print('🚀 Local webhook server running on:');
  print('   http://localhost:$port');
  print('   http://127.0.0.1:$port');
  print('');
  print('🔗 Use this webhook URL in your requests:');
  print('   http://localhost:$port/api/webhook/music');
  print('');
  print('💡 For external testing (if kie.ai needs public access):');
  print('   Use ngrok: ngrok http $port');
  print('   Then use: https://your-ngrok-url.ngrok.io/api/webhook/music');
  print('');
  print('🛑 Press Ctrl+C to stop the server');
  print('=' * 60);
}

/// Validate kie.ai webhook payload structure
bool _isValidKieAiWebhook(Map<String, dynamic> payload) {
  return payload.containsKey('code') &&
         payload.containsKey('data') &&
         payload['data'] is Map<String, dynamic>;
}