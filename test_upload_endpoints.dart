// Test different possible upload endpoints for kie.ai
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = '2ecfa565693e419f371eff8c5da05833';

  // Possible upload endpoints to test
  final endpoints = [
    'https://api.kie.ai/api/file-stream-upload',
    'https://api.kie.ai/api/v1/file-stream-upload',
    'https://api.kie.ai/api/upload',
    'https://api.kie.ai/api/v1/upload',
    'https://api.kie.ai/api/file-upload',
    'https://api.kie.ai/api/v1/file-upload',
  ];

  final testBytes = List.generate(1000, (i) => i % 256);

  for (final endpoint in endpoints) {
    print('\n🔍 Testing endpoint: $endpoint');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.headers['Accept'] = 'application/json';

      // Try different field names
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Try 'file' first
          testBytes,
          filename: 'test_voice.webm',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ SUCCESS! This endpoint works!');

        // Parse the response to understand the format
        try {
          final jsonResponse = jsonDecode(response.body);
          print('📋 Parsed JSON: $jsonResponse');

          // Look for common field names
          if (jsonResponse is Map) {
            final possibleFields = ['downloadUrl', 'download_url', 'url', 'file_url', 'fileUrl', 'link'];
            for (final field in possibleFields) {
              if (jsonResponse.containsKey(field)) {
                print('🔗 Found URL field: $field = ${jsonResponse[field]}');
              }
            }
          }
        } catch (e) {
          print('❌ Failed to parse JSON: $e');
        }
        break;
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // Also test if there's a different upload method needed
  print('\n🔍 Testing alternative upload methods...');

  // Try with base64 encoded data
  final base64Data = 'base64:' + base64Encode(testBytes);

  final jsonEndpoints = [
    'https://api.kie.ai/api/v1/generate',
    'https://api.kie.ai/api/v1/wav/generate',
  ];

  for (final endpoint in jsonEndpoints) {
    print('\n🔍 Testing JSON endpoint: $endpoint');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'audioData': base64Data,
          'filename': 'test_voice.webm',
          'format': 'webm',
        }),
      );

      print('📤 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}