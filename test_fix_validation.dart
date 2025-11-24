import 'dart:io';
import 'dart:convert';

/// Simple test to validate the music generation fix
void main() async {
  print('🧪 Validating Music Generation Fix...\n');

  // Test 1: Check if the fixed files exist and have the expected content
  await validateFix();

  print('\n✅ Fix validation completed!');
}

Future<void> validateFix() async {
  print('1. Checking if files contain the fix...');

  // Check AIMusicStudioScreen for the database service import
  final studioFile = File('lib/screens/ai_music_studio_screen.dart');
  if (await studioFile.exists()) {
    final content = await studioFile.readAsString();
    if (content.contains("import '../services/track_database_service.dart';")) {
      print('   ✅ Database service import added');
    } else {
      print('   ❌ Database service import missing');
    }

    if (content.contains("_databaseService.saveTrack(track)")) {
      print('   ✅ Database save functionality added');
    } else {
      print('   ❌ Database save functionality missing');
    }

    if (content.contains("TrackListWidget.globalKey.currentState?.refreshTracks()")) {
      print('   ✅ Track list refresh added');
    } else {
      print('   ❌ Track list refresh missing');
    }
  } else {
    print('   ❌ Studio file not found');
  }

  // Check TrackListWidget for refresh functionality
  final trackListFile = File('lib/widgets/track_list_widget.dart');
  if (await trackListFile.exists()) {
    final content = await trackListFile.readAsString();
    if (content.contains("Future<void> refreshTracks()")) {
      print('   ✅ Public refresh method added');
    } else {
      print('   ❌ Public refresh method missing');
    }

    if (content.contains("static final GlobalKey")) {
      print('   ✅ GlobalKey for external access added');
    } else {
      print('   ❌ GlobalKey missing');
    }
  } else {
    print('   ❌ Track list file not found');
  }

  print('');
}