// Test Upload and Cover Audio API to see if it accepts direct audio data
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = '2ecfa565693e419f371eff8c5da05833';

  // Create a test audio data (base64 encoded)
  final testAudioData = base64Encode(List.generate(1000, (i) => i % 256));

  print('🔍 Testing Upload and Cover Audio API with different approaches...\n');

  // Test 1: Try with uploadUrl parameter (current implementation)
  print('📤 Test 1: Using uploadUrl parameter');
  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate/upload-cover'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'upload_url': 'https://example.com/test.webm', // Test URL
        'prompt': 'Test prompt for voice cover',
        'style': 'pop, upbeat',
        'title': 'Test Cover',
        'custom_mode': true,
        'instrumental': false,
        'model': 'V5',
        'callback_url': 'https://test.com/callback',
        'duration': 30,
        'quality': 'high',
      }),
    );

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');
    print('');
  } catch (e) {
    print('   Error: $e');
    print('');
  }

  // Test 2: Try with audio_data parameter (base64)
  print('📤 Test 2: Using audio_data parameter with base64');
  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate/upload-cover'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'audio_data': testAudioData,
        'audio_filename': 'test.webm',
        'prompt': 'Test prompt for voice cover',
        'style': 'pop, upbeat',
        'title': 'Test Cover',
        'custom_mode': true,
        'instrumental': false,
        'model': 'V5',
        'callback_url': 'https://test.com/callback',
      }),
    );

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');
    print('');
  } catch (e) {
    print('   Error: $e');
    print('');
  }

  // Test 3: Try direct file upload with multipart
  print('📤 Test 3: Direct multipart upload to upload-cover endpoint');
  try {
    final request = http.MultipartRequest('POST', Uri.parse('https://api.kie.ai/api/v1/generate/upload-cover'));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Accept'] = 'application/json';

    // Add audio file
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio', // Try 'audio' field name
        List.generate(1000, (i) => i % 256),
        filename: 'test_voice.webm',
      ),
    );

    // Add other fields
    request.fields['prompt'] = 'Test prompt for voice cover';
    request.fields['style'] = 'pop, upbeat';
    request.fields['title'] = 'Test Cover';
    request.fields['custom_mode'] = 'true';
    request.fields['instrumental'] = 'false';
    request.fields['model'] = 'V5';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');
    print('');
  } catch (e) {
    print('   Error: $e');
    print('');
  }

  // Test 4: Check if there's a direct voice-to-music endpoint
  print('📤 Test 4: Testing direct voice-to-music generation');
  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': 'V5',
        'prompt': 'Convert this voice recording to a song',
        'tags': 'voice cover, pop, upbeat',
        'title': 'Test Song',
        'audio_url': 'https://example.com/test.webm', // Test URL
      }),
    );

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');
    print('');
  } catch (e) {
    print('   Error: $e');
    print('');
  }

  // Test 5: Check available endpoints
  print('📤 Test 5: Checking what endpoints are available');
  try {
    final response = await http.get(
      Uri.parse('https://api.kie.ai/api/v1'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');
    print('');
  } catch (e) {
    print('   Error: $e');
    print('');
  }

  print('✅ Testing completed!');
}