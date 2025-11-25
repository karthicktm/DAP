import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../models/generated_track.dart';
import '../services/track_database_service.dart';
import '../models/ai_track.dart';

/// Service to handle webhook callbacks and polling
class WebhookService {
  static const String _defaultWebhookPath = '/api/webhook/music';

  /// Get the webhook URL for the current deployment
  static String getWebhookUrl() {
    String webhookUrl;

    // Check if we're running on Railway (detect by hostname)
    if (_isRunningOnRailway()) {
      // Use your actual Railway URL
      webhookUrl = 'https://dap-production-99ef.up.railway.app$_defaultWebhookPath';
      Logger.log('🌐 Using Railway webhook URL: $webhookUrl');
      return webhookUrl;
    }

    // In production (Railway), use the deployment URL
    const railwayUrl = String.fromEnvironment('RAILWAY_STATIC_URL');
    const customDomain = String.fromEnvironment('CUSTOM_DOMAIN');

    if (railwayUrl.isNotEmpty) {
      webhookUrl = 'https://$railwayUrl$_defaultWebhookPath';
      Logger.log('🌐 Using environment Railway URL: $webhookUrl');
      return webhookUrl;
    } else if (customDomain.isNotEmpty) {
      webhookUrl = 'https://$customDomain$_defaultWebhookPath';
      Logger.log('🌐 Using custom domain URL: $webhookUrl');
      return webhookUrl;
    } else {
      // For local development, return a placeholder
      webhookUrl = 'https://localhost:3000$_defaultWebhookPath';
      Logger.log('⚠️ Falling back to localhost URL: $webhookUrl (webhooks will not work)');
      return webhookUrl;
    }
  }

  /// Check if running on Railway by detecting the hostname
  static bool _isRunningOnRailway() {
    // In Flutter web, check if we're running on a Railway domain
    try {
      // This will work in Flutter web to detect the current domain
      final currentUrl = Uri.base.toString();
      Logger.log('🔍 Current URL detected: $currentUrl');

      final isRailway = currentUrl.contains('railway.app') ||
                       currentUrl.contains('dap-production-99ef.up.railway.app');

      Logger.log('🚂 Running on Railway: $isRailway');
      return isRailway;
    } catch (e) {
      Logger.log('❌ Error detecting Railway: $e');
      return false;
    }
  }

  /// Check if we're in a webhook-capable environment
  static bool isWebhookCapable() {
    const railwayUrl = String.fromEnvironment('RAILWAY_STATIC_URL');
    const customDomain = String.fromEnvironment('CUSTOM_DOMAIN');

    return railwayUrl.isNotEmpty || customDomain.isNotEmpty;
  }

  /// Process webhook payload from kie.ai
  static Future<void> processWebhook(Map<String, dynamic> payload) async {
    try {
      Logger.log('🔔 Processing kie.ai webhook payload: $payload');

      // Validate webhook payload structure according to kie.ai docs
      if (!_isValidKieAiWebhookPayload(payload)) {
        Logger.log('❌ Invalid kie.ai webhook payload received');
        return;
      }

      final code = payload['code'] as int?;
      final data = payload['data'] as Map<String, dynamic>?;

      if (code != 200 || data == null) {
        Logger.log('❌ Webhook returned error code: $code');
        return;
      }

      final callbackType = data['callbackType'] as String?;
      final taskId = data['task_id'] as String? ?? data['taskId'] as String?;
      final trackDataList = data['data'] as List?;

      if (taskId == null) {
        Logger.log('❌ Webhook missing taskId');
        return;
      }

      Logger.log('📋 Webhook details: callbackType=$callbackType, taskId=$taskId');

      if (callbackType == 'complete' && trackDataList != null && trackDataList.isNotEmpty) {
        // Extract the first track data (kie.ai can return multiple tracks)
        final firstTrack = trackDataList[0] as Map<String, dynamic>;

        Logger.log('🎵 Processing completed track from webhook:');
        Logger.log('   Title: ${firstTrack['title']}');
        Logger.log('   Audio URL: ${firstTrack['audio_url'] ?? firstTrack['audioUrl']}');
        Logger.log('   Duration: ${firstTrack['duration']}');

        // Update the existing processing track in Supabase
        await _updateTrackFromWebhook(taskId, firstTrack);

      } else if (callbackType == 'first' && trackDataList != null && trackDataList.isNotEmpty) {
        // First track completed - update status but keep processing
        final firstTrack = trackDataList[0] as Map<String, dynamic>;
        Logger.log('🎵 First track completed: ${firstTrack['title']}');

        await _updateProcessingStatus(taskId, 'First track completed - generating remaining tracks...');

      } else if (callbackType == 'text') {
        // Text generation completed
        Logger.log('📝 Text generation completed for taskId: $taskId');
        await _updateProcessingStatus(taskId, 'Text generated - creating audio...');

      } else {
        Logger.log('⚠️ Unknown callback type or missing data: $callbackType');
      }

    } catch (e) {
      Logger.log('❌ Error processing kie.ai webhook: $e');
    }
  }

  /// Validate kie.ai webhook payload structure
  static bool _isValidKieAiWebhookPayload(Map<String, dynamic> payload) {
    return payload.containsKey('code') &&
           payload.containsKey('data') &&
           payload['data'] is Map<String, dynamic>;
  }

  /// Update processing track with completed data from webhook
  static Future<void> _updateTrackFromWebhook(String taskId, Map<String, dynamic> trackData) async {
    try {
      final databaseService = TrackDatabaseService();

      // Create updated track with real data from kie.ai
      final updatedTrack = AITrack(
        id: taskId,
        title: trackData['title'] ?? 'AI Generated Track',
        artist: 'AI Artist',
        genre: trackData['tags'] ?? 'AI Music',
        mood: 'Generated',
        duration: Duration(seconds: (trackData['duration'] is num) ? trackData['duration'].toInt() : 120),
        audioUrl: trackData['audio_url'] ?? trackData['audioUrl'] ?? '',
        coverArtUrl: trackData['image_url'] ?? trackData['imageUrl'] ?? '',
        createdAt: DateTime.parse(trackData['createTime'] ?? DateTime.now().toIso8601String()),
        isInstrumental: false,
        lyrics: null,
        isProcessing: false,
        processingCompleted: true,
        processingStatus: 'Completed via webhook',
        metadata: {
          'taskId': taskId,
          'sunoId': trackData['id'] ?? '',
          'prompt': trackData['prompt'] ?? '',
          'model_name': trackData['model_name'] ?? 'V5',
          'tags': trackData['tags'] ?? '',
          'streamAudioUrl': trackData['stream_audio_url'] ?? trackData['streamAudioUrl'] ?? '',
          'webhookReceived': true,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      // Update the track in Supabase
      final success = await databaseService.saveTrack(updatedTrack);

      if (success) {
        Logger.log('✅ Track updated in Supabase with real audio URL: ${trackData['audioUrl']}');
        _notifyTrackCompleted(updatedTrack);
      } else {
        Logger.log('❌ Failed to update track in Supabase');
      }

    } catch (e) {
      Logger.log('❌ Error updating track from webhook: $e');
    }
  }

  /// Update processing status for a track
  static Future<void> _updateProcessingStatus(String taskId, String status) async {
    try {
      final databaseService = TrackDatabaseService();
      await databaseService.updateProcessingStatus(taskId, status);
      Logger.log('📱 Updated processing status for $taskId: $status');
    } catch (e) {
      Logger.log('❌ Error updating processing status: $e');
    }
  }

  /// Extract track data from webhook payload
  static GeneratedTrack? _extractTrackFromWebhook(Map<String, dynamic> payload) {
    try {
      // Adapt this based on actual kie.ai webhook format
      if (payload.containsKey('track') && payload['track'] != null) {
        return GeneratedTrack.fromJson(payload['track']);
      } else if (payload.containsKey('audio_url')) {
        // Direct track data in webhook
        return GeneratedTrack.fromJson(payload);
      }
      return null;
    } catch (e) {
      Logger.log('Error extracting track from webhook: $e');
      return null;
    }
  }

  /// Notify UI that track is completed
  static void _notifyTrackCompleted(AITrack track) {
    // Notification will happen through Supabase real-time updates
    // The UI should listen to database changes for the track list
    Logger.log('🎵 Track generation completed via webhook: ${track.title}');
    Logger.log('🔗 Audio URL available: ${track.audioUrl}');
  }

  /// Notify UI that track failed
  static void _notifyTrackFailed(String taskId, String error) {
    // Update the processing track to show failure status
    Logger.log('💥 Track generation failed for $taskId: $error');
    _updateProcessingStatus(taskId, 'Failed: $error');
  }
}