import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Script to fix existing tracks with corrupted metadata from webhook bug
///
/// This addresses tracks that were saved with:
/// - Generic titles like "AI Generated Track"
/// - Hardcoded artist "AI Artist"
/// - Potentially missing or wrong audio URLs
///
/// The script will:
/// 1. Find tracks with generic metadata
/// 2. Try to restore original metadata from the 'metadata' field
/// 3. Fix audio URL field naming issues
/// 4. Update tracks with corrected information

void main() async {
  print('🔧 Starting track metadata fix...');

  // Get Supabase credentials from environment
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Missing Supabase credentials in environment variables');
    print('Set SUPABASE_URL and SUPABASE_ANON_KEY and try again');
    return;
  }

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    final supabase = Supabase.instance.client;
    print('✅ Connected to Supabase');

    // Get all tracks with corrupted metadata
    final response = await supabase
        .from('tracks')
        .select('*')
        .order('created_at', ascending: false);

    print('📊 Found ${response.length} tracks to analyze');

    int fixedCount = 0;
    int skippedCount = 0;

    for (final track in response) {
      final id = track['id'];
      final title = track['title'];
      final artist = track['artist'];
      final audioUrl = track['audio_url'];
      final metadata = track['metadata'] as Map<String, dynamic>? ?? {};

      print('\n🔍 Analyzing track: $id');
      print('   Current title: $title');
      print('   Current artist: $artist');
      print('   Audio URL: ${audioUrl?.substring(0, (audioUrl?.length ?? 0).clamp(0, 50))}...');

      bool needsFixing = false;
      Map<String, dynamic> updates = {};

      // Check if this track has generic/corrupted metadata
      if (title == 'AI Generated Track' ||
          title?.startsWith('Generating:') == true ||
          artist == 'AI Artist' ||
          artist == 'AI Music Generator') {

        print('   ❌ Found corrupted metadata');
        needsFixing = true;

        // Try to restore original metadata from the metadata field
        final originalDescription = metadata['originalDescription'] as String?;
        final musicPrompt = metadata['musicPrompt'] as String?;
        final requestedGenre = metadata['requestedGenre'] as String?;
        final requestedMood = metadata['requestedMood'] as String?;

        // Generate better title and artist from available data
        String newTitle = title ?? 'Restored Track';
        String newArtist = 'AI Artist';

        if (originalDescription != null && originalDescription.isNotEmpty) {
          // Use the original user description as title
          newTitle = originalDescription.length > 50
              ? originalDescription.substring(0, 47) + '...'
              : originalDescription;
        } else if (musicPrompt != null && musicPrompt.isNotEmpty) {
          // Extract meaningful parts from the music prompt
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

        // Set artist based on genre/mood or keep it generic but better
        if (requestedGenre != null && requestedMood != null) {
          newArtist = '$requestedGenre AI · $requestedMood';
        } else if (requestedGenre != null) {
          newArtist = '$requestedGenre AI Artist';
        } else {
          newArtist = 'AI Generated';
        }

        updates['title'] = newTitle;
        updates['artist'] = newArtist;

        print('   ✅ New title: $newTitle');
        print('   ✅ New artist: $newArtist');
      }

      // Check for missing audio URL (could be empty or null)
      if (audioUrl == null || audioUrl.isEmpty || audioUrl == '') {
        print('   ❌ Missing audio URL');
        needsFixing = true;

        // Try to get audio URL from metadata
        final streamAudioUrl = metadata['streamAudioUrl'] as String?;
        if (streamAudioUrl != null && streamAudioUrl.isNotEmpty) {
          updates['audio_url'] = streamAudioUrl;
          print('   ✅ Restored audio URL from metadata');
        } else {
          print('   ⚠️ No audio URL found in metadata - track may be incomplete');
        }
      }

      // Apply fixes if needed
      if (needsFixing && updates.isNotEmpty) {
        try {
          await supabase
              .from('tracks')
              .update(updates)
              .eq('id', id);

          print('   ✅ Fixed track $id');
          fixedCount++;
        } catch (e) {
          print('   ❌ Error fixing track $id: $e');
        }
      } else {
        print('   ✅ Track looks good, no fixes needed');
        skippedCount++;
      }
    }

    print('\n🎉 Migration completed!');
    print('   ✅ Fixed: $fixedCount tracks');
    print('   ⏭️  Skipped: $skippedCount tracks (already good)');
    print('   📊 Total: ${fixedCount + skippedCount} tracks processed');

  } catch (e) {
    print('❌ Error during migration: $e');
  }
}