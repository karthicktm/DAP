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
      Logger.log('Processing webhook payload: $payload');

      // Validate webhook payload
      if (!_isValidWebhookPayload(payload)) {
        Logger.log('Invalid webhook payload received');
        return;
      }

      final taskId = payload['taskId'] as String?;
      final status = payload['status'] as String?;

      if (taskId == null) {
        Logger.log('Webhook missing taskId');
        return;
      }

      if (status == 'completed' || status == 'success') {
        // Extract track data from webhook
        final trackData = _extractTrackFromWebhook(payload);

        if (trackData != null) {
          Logger.log('✅ Track received from webhook: ${trackData.title}');

          // Save track to database
          try {
            final aiTrack = AITrack(
              id: trackData.id,
              title: trackData.title,
              artist: trackData.artist,
              genre: trackData.genre,
              mood: trackData.mood,
              duration: Duration(seconds: trackData.duration),
              audioUrl: trackData.audioUrl,
              coverArtUrl: trackData.coverImageUrl,
              createdAt: DateTime.now(),
              isInstrumental: false,
              lyrics: null,
            );

            await TrackDatabaseService().saveTrack(aiTrack);

            Logger.log('✅ Track saved to database: ${trackData.title}');
            _notifyTrackCompleted(trackData);
          } catch (e) {
            Logger.log('❌ Failed to save track to Supabase: $e');
            // Still notify UI that track is available, even if save failed
            _notifyTrackCompleted(trackData);
          }
        }
      } else if (status == 'failed' || status == 'error') {
        final errorMessage = payload['error'] as String? ?? 'Unknown error';
        Logger.log('❌ Track generation failed via webhook: $errorMessage');

        // Notify UI of failure
        _notifyTrackFailed(taskId, errorMessage);
      }

    } catch (e) {
      Logger.log('Error processing webhook: $e');
    }
  }

  /// Validate incoming webhook payload
  static bool _isValidWebhookPayload(Map<String, dynamic> payload) {
    // Basic validation - you might want to add signature verification
    return payload.containsKey('taskId') &&
           payload.containsKey('status');
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
  static void _notifyTrackCompleted(GeneratedTrack track) {
    // Implement notification mechanism (streams, callbacks, etc.)
    Logger.log('🎵 Track generation completed: ${track.title}');
  }

  /// Notify UI that track failed
  static void _notifyTrackFailed(String taskId, String error) {
    // Implement failure notification
    Logger.log('💥 Track generation failed for $taskId: $error');
  }
}