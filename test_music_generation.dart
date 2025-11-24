import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Test script to debug the music generation workflow
void main() async {
  print('🔍 Testing Music Generation Workflow...\n');

  // Test 1: API Endpoint Accessibility
  await testApiEndpoint();

  // Test 2: Mock Music Generation (simulate service behavior)
  await testMockGeneration();

  print('\n✅ Testing completed!');
}

Future<void> testApiEndpoint() async {
  print('1. Testing API Endpoint Accessibility...');

  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true; // Ignore SSL for testing

    final request = await client.postUrl(Uri.parse('https://api.kie.ai/api/v1/generate'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer test-key-for-validation');

    const requestData = '''
    {
      "prompt": "test electronic music",
      "model": "V5",
      "callBackUrl": "https://test.com/webhook",
      "customMode": false,
      "instrumental": true,
      "genre": "electronic",
      "mood": "energetic",
      "duration": 60
    }
    ''';

    request.add(utf8.encode(requestData));

    final response = await request.close().timeout(Duration(seconds: 10));
    final responseBody = await response.transform(utf8.decoder).join();

    print('   Status Code: ${response.statusCode}');
    print('   Response: $responseBody');

    if (response.statusCode == 401) {
      print('   ✅ API is accessible but requires valid authentication');
    } else if (response.statusCode == 200) {
      print('   ✅ API call successful');
    } else {
      print('   ⚠️ Unexpected response: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('   ❌ API test failed: $e');
  }

  print('');
}

Future<void> testMockGeneration() async {
  print('2. Testing Mock Music Generation Logic...');

  try {
    // Simulate the logic from AIMusicService._createMockTrack()
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final trackId = 'mock_$timestamp';

    const prompt = 'Upbeat electronic music with modern production';
    const genre = 'electronic';
    const mood = 'energetic';
    const duration = 120;

    // Generate mock title based on prompt
    String title = 'AI Generated Track';
    if (prompt.isNotEmpty) {
      final words = prompt.split(' ').take(3).join(' ');
      title = '${words[0].toUpperCase()}${words.substring(1)}';
    }

    // Generate mock artist name
    final artists = ['AI Composer', 'Digital Maestro', 'Virtual Artist', 'Code Musician', 'Algorithm Creator'];
    final artist = artists[timestamp % artists.length];

    // Generate mock URLs
    final audioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-${(timestamp % 10) + 1}.mp3';
    final coverImageUrl = 'https://picsum.photos/300/300?random=$timestamp';

    // Generate metadata
    final metadata = {
      'prompt': prompt,
      'style': 'modern',
      'instrumental': false,
      'model': 'suno-v5',
      'temperature': 0.7,
      'generated_at': DateTime.now().toIso8601String(),
      'mock': true,
    };

    final mockTrack = {
      'id': trackId,
      'title': title,
      'artist': artist,
      'genre': genre,
      'mood': mood,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'created_at': DateTime.now().toIso8601String(),
      'metadata': metadata,
    };

    print('   ✅ Mock track generated successfully:');
    print('   ID: ${mockTrack['id']}');
    print('   Title: ${mockTrack['title']}');
    print('   Artist: ${mockTrack['artist']}');
    print('   Audio URL: ${mockTrack['audio_url']}');
    print('   Cover URL: ${mockTrack['cover_image_url']}');
    print('   Is Mock: ${(mockTrack['metadata'] as Map<String, dynamic>)['mock']}');

    // Test if audio URL is accessible
    await testAudioUrl(mockTrack['audio_url'] as String);

  } catch (e) {
    print('   ❌ Mock generation failed: $e');
  }

  print('');
}

Future<void> testAudioUrl(String audioUrl) async {
  print('   3. Testing Mock Audio URL Accessibility...');

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(audioUrl));
    final response = await request.close().timeout(Duration(seconds: 5));

    print('      Audio URL Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('      ✅ Mock audio URL is accessible');
    } else {
      print('      ⚠️ Mock audio URL returned: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('      ⚠️ Mock audio URL not accessible: $e');
    print('      (This is expected for mock URLs)');
  }
}