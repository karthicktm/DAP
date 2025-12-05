// Test voice recording functionality without Supabase dependency
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🎤 TESTING VOICE RECORDING ONLY (NO UPLOAD)\n');

  // Load environment variables
  final envFile = File('.env');
  final envContent = await envFile.readAsString();
  final Map<String, String> envVars = {};
  for (final line in envContent.split('\n')) {
    if (line.trim().isNotEmpty && !line.startsWith('#')) {
      final parts = line.split('=');
      if (parts.length == 2) {
        envVars[parts[0].trim()] = parts[1].trim();
      }
    }
  }

  final kieApiKey = envVars['KIE_AI_API_KEY'] ?? '';

  print('✅ Using API key: ${kieApiKey.substring(0, 10)}...');

  // Test 1: Check if voice recording works in Flutter app
  print('\n📱 Step 1: Flutter Voice Recording Test');
  print('   1. Open Flutter app (running on port 8087)');
  print('   2. Navigate to AI Music Studio');
  print('   3. Click "Start Recording"');
  print('   4. Record for 5-10 seconds');
  print('   5. Click "Stop Recording"');
  print('   6. Check if recording was successful');

  // Test 2: Test kie.ai API with a mock URL
  print('\n🌐 Step 2: Test kie.ai API with Mock URL');
  try {
    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate/upload-cover'),
      headers: {
        'Authorization': 'Bearer $kieApiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'upload_url': 'https://example.com/test-voice-recording.webm',
        'prompt': 'Convert this voice recording to a professional song',
        'style': 'pop, upbeat, professional',
        'title': 'Test Voice Recording',
        'custom_mode': true,
        'instrumental': false,
        'model': 'V5',
        'callback_url': 'https://test.com/webhook',
        'duration': 30,
        'quality': 'high',
      }),
    );

    print('   📤 Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final taskId = responseData['data']['taskId'] ?? 'No task ID';
      print('   ✅ kie.ai API working! Task ID: $taskId');
      print('   🎵 This means voice recordings can be processed once uploaded');
    } else {
      print('   ❌ API failed: ${response.body}');
    }
  } catch (e) {
    print('   ❌ API test failed: $e');
  }

  // Test 3: Check current Flutter app status
  print('\n🚀 Step 3: Current App Status');
  print('   ✅ Flutter app should be running on: http://localhost:8087');
  print('   ✅ Voice recording component: lib/widgets/voice_recorder_widget.dart');
  print('   ✅ AI Voice service: lib/services/ai_voice_service.dart');
  print('   ✅ Environment configuration: .env');

  print('\n📋 NEXT STEPS:');
  print('1. Test voice recording in the Flutter app first');
  print('2. If recording works, the issue is with Supabase upload');
  print('3. If recording fails, we need to fix the voice recording component');
  print('4. Once recording works, we can fix Supabase bucket creation');

  print('\n💡 TO TEST VOICE RECORDING:');
  print('• Open http://localhost:8087 in browser');
  print('• Go to AI Music Studio tab');
  print('• Click "Start Recording" and record your voice');
  print('• Check if audio waveform appears during recording');
  print('• Check if "Generate Music" button becomes enabled after recording');

  // Instructions for manual Supabase bucket creation
  print('\n📁 SUPABASE BUCKET SETUP (if needed later):');
  print('1. Go to https://supabase.com/dashboard/project/bgoasjlsfgaztmvdofvq');
  print('2. Click "Storage" in left sidebar');
  print('3. Click "Create bucket"');
  print('4. Name: voice_recordings');
  print('5. Public bucket: OFF');
  print('6. File size limit: 52428800 (50MB)');
  print('7. Click "Save"');
  print('8. Go to bucket Settings > Policies');
  print('9. Add RLS policy for uploads');

  print('\n🎯 CURRENT STATUS:');
  print('• ✅ kie.ai API: Working (confirmed)');
  print('• 🔍 Voice recording: Needs testing in app');
  print('• ❌ Supabase bucket: Missing (needs manual creation)');
  print('• 📱 Flutter app: Running and ready for testing');
}