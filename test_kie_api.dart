// Test script to verify kie.ai API integration works correctly
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing kie.ai API integration...');

  // Check if API key is available
  final apiKey = Platform.environment['KIE_AI_API_KEY'] ?? 'test-key';
  if (apiKey == 'test-key') {
    print('⚠️ No KIE_AI_API_KEY environment variable found');
    print('💡 To test with real API: export KIE_AI_API_KEY=your_key');
    print('📋 Testing API structure and endpoints instead...');
  }

  await testApiEndpoints(apiKey);
  await testDataFormats();
  await testErrorHandling();

  print('✅ API integration tests completed!');
}

Future<void> testApiEndpoints(String apiKey) async {
  print('\n🔗 Testing API endpoints...');

  // Test file upload endpoint structure with correct endpoint
  final testBytes = List.generate(1000, (i) => i % 256);

  try {
    // Test the corrected file-stream-upload endpoint with multipart
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.kie.ai/api/file-stream-upload'),
    );

    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        testBytes,
        filename: 'test_voice.webm',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📤 File upload endpoint: ${response.statusCode}');
    if (response.statusCode == 401) {
      print('🔑 Authentication required (expected for test)');
    } else if (response.statusCode == 200) {
      print('✅ File upload successful!');
      final result = jsonDecode(response.body);
      print('📄 Response: $result');
    } else {
      print('❌ Unexpected response: ${response.statusCode}');
      print('📄 Body: ${response.body}');
    }
  } catch (e) {
    print('❌ File upload test error: $e');
  }

  // Test Add Vocals endpoint structure
  final addVocalsData = {
    'prompt': 'Add smooth vocals to this instrumental track',
    'audioUrl': 'https://test-upload-url.com/file.webm',
    'model': 'V5',
    'callBackUrl': 'https://test-webhook.com/callback',
  };

  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate/add-vocals'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(addVocalsData),
    );

    print('🎤 Add Vocals endpoint: ${response.statusCode}');
    if (response.statusCode == 401) {
      print('🔑 Authentication required (expected for test)');
    } else if (response.statusCode == 200) {
      print('✅ Add Vocals request successful!');
      final result = jsonDecode(response.body);
      print('📄 Response: $result');
    } else {
      print('❌ Unexpected response: ${response.statusCode}');
      print('📄 Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Add Vocals test error: $e');
  }
}

Future<void> testDataFormats() async {
  print('\n📋 Testing data format handling...');

  // Test Base64 encoding (simulating audio data)
  final testAudio = List.generate(1000, (i) => i % 256);
  final base64Audio = base64Encode(testAudio);

  if (base64Audio.isNotEmpty) {
    print('✅ Base64 encoding works');
    print('📏 Encoded length: ${base64Audio.length} characters');
  }

  // Test JSON serialization
  final testData = {
    'audioData': base64Audio.substring(0, 100), // First 100 chars
    'metadata': {
      'filename': 'test.webm',
      'duration': 30,
      'sampleRate': 44100,
    },
  };

  try {
    final jsonString = jsonEncode(testData);
    final decoded = jsonDecode(jsonString);

    if (decoded['audioData'] == testData['audioData'] &&
        decoded['metadata']['filename'] == 'test.webm') {
      print('✅ JSON serialization works');
    } else {
      print('❌ JSON serialization failed');
    }
  } catch (e) {
    print('❌ JSON test error: $e');
  }
}

Future<void> testErrorHandling() async {
  print('\n🛡️ Testing error handling...');

  // Test with invalid endpoint
  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/invalid-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'test': 'data'}),
    );

    print('🔍 Invalid endpoint test: ${response.statusCode}');
    if (response.statusCode == 404) {
      print('✅ 404 handling works correctly');
    }
  } catch (e) {
    print('✅ Network error handling works: ${e.runtimeType}');
  }

  // Test with malformed JSON
  try {
    jsonDecode('invalid json {');
    print('❌ JSON error handling failed');
  } catch (e) {
    print('✅ JSON error handling works: ${e.runtimeType}');
  }
}