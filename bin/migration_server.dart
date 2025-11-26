import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;
import 'package:supabase/supabase.dart';

/// Migration server to fix existing tracks with corrupted metadata
///
/// Deployed to Railway and can be triggered via HTTP endpoint
/// GET /migrate/tracks - Runs the track metadata migration
/// GET /migrate/status - Shows migration status/stats

late SupabaseClient supabase;

void main() async {
  print('🔧 Starting Migration Server...');

  // Initialize Supabase
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('❌ Missing Supabase credentials');
    exit(1);
  }

  supabase = SupabaseClient(supabaseUrl, supabaseKey);
  print('✅ Connected to Supabase');

  final app = Router();

  // Migration endpoint
  app.get('/migrate/tracks', _runTrackMigration);

  // Status endpoint
  app.get('/migrate/status', _getMigrationStatus);

  // Health check
  app.get('/health', (Request request) {
    return Response.ok('Migration server is healthy');
  });

  // CORS headers for web access
  final corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(
    Pipeline()
        .addMiddleware(cors.corsHeaders(headers: corsHeaders))
        .addHandler(app),
    InternetAddress.anyIPv4,
    port,
  );

  print('🚀 Migration server running on port $port');
  print('🔗 Migration URL: https://your-railway-url.up.railway.app/migrate/tracks');
}

Future<Response> _runTrackMigration(Request request) async {
  try {
    print('🔧 Starting track metadata migration...');

    // Get all tracks
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

        // Try to restore original metadata
        final originalDescription = metadata['originalDescription'] as String?;
        final musicPrompt = metadata['musicPrompt'] as String?;
        final requestedGenre = metadata['requestedGenre'] as String?;
        final requestedMood = metadata['requestedMood'] as String?;

        // Generate better title and artist
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
        results.add({
          'id': id,
          'status': 'skipped',
          'reason': 'no_fixes_needed',
        });
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
      'results': results.take(10).toList(), // Show first 10 for brevity
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('🎉 Migration completed: $fixedCount fixed, $skippedCount skipped');

    return Response.ok(
      jsonEncode(migrationResult),
      headers: {'Content-Type': 'application/json'},
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

Future<Response> _getMigrationStatus(Request request) async {
  try {
    // Get track statistics
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
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response.ok(
      jsonEncode(status),
      headers: {'Content-Type': 'application/json'},
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