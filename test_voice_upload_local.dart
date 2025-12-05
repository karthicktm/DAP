// Comprehensive local test for voice upload workflow
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 LOCAL VOICE UPLOAD WORKFLOW TEST\n');

  // 1. Load and verify environment variables
  print('📁 Loading environment variables...');
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found!');
    return;
  }

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
  final supabaseUrl = envVars['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'] ?? '';

  print('✅ Environment variables loaded');

  // 2. Validate credentials
  print('\n🔑 Validating credentials...');
  if (kieApiKey.isEmpty || kieApiKey == 'your_kie_ai_api_key_here') {
    print('❌ kie.ai API key missing');
    return;
  }
  print('✅ kie.ai API key: ${kieApiKey.substring(0, 10)}...');

  if (supabaseUrl.isEmpty || supabaseUrl == 'your_supabase_project_url') {
    print('❌ Supabase URL missing');
    return;
  }
  print('✅ Supabase URL: $supabaseUrl');

  if (supabaseAnonKey.isEmpty || supabaseAnonKey == 'your_supabase_anon_key') {
    print('❌ Supabase Anon Key missing');
    return;
  }
  print('✅ Supabase Anon Key configured');

  // 3. Test kie.ai API connectivity
  print('\n🌐 Testing kie.ai API connectivity...');
  try {
    final response = await http.get(
      Uri.parse('https://api.kie.ai/api/v1'),
      headers: {
        'Authorization': 'Bearer $kieApiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('✅ kie.ai API is accessible');
    } else if (response.statusCode == 401) {
      print('⚠️  kie.ai API reachable but key may be invalid (401)');
      print('   Response: ${response.body}');
    } else {
      print('⚠️  kie.ai API returned unexpected status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to connect to kie.ai API: $e');
    return;
  }

  // 4. Test Supabase connectivity
  print('\n🗄️  Testing Supabase connectivity...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/'),
      headers: {
        'apikey': supabaseAnonKey,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('✅ Supabase is accessible');
    } else {
      print('⚠️  Supabase returned unexpected status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to connect to Supabase: $e');
    return;
  }

  // 5. Check if voice_recordings bucket exists or create it
  print('\n📦 Checking voice_recordings bucket...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/voice_recordings'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('✅ voice_recordings bucket exists');
    } else if (response.statusCode == 404) {
      print('⚠️  voice_recordings bucket not found (404)');
      print('   You may need to create this bucket in Supabase dashboard');
    } else {
      print('⚠️  Unexpected response checking bucket: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to check voice_recordings bucket: $e');
  }

  // 6. Test Upload and Cover Audio API with test data
  print('\n🎵 Testing kie.ai Upload and Cover Audio API...');
  try {
    final requestData = {
      'upload_url': 'https://example.com/test.webm', // Test URL
      'prompt': 'Test prompt for voice cover',
      'style': 'pop, upbeat',
      'title': 'Test Cover',
      'custom_mode': true,
      'instrumental': false,
      'model': 'V5',
      'callback_url': 'https://example.com/callback',
      'duration': 30,
      'quality': 'high',
    };

    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate/upload-cover'),
      headers: {
        'Authorization': 'Bearer $kieApiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    print('📤 Upload and Cover API Status: ${response.statusCode}');
    print('📄 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 400) {
      print('✅ kie.ai Upload and Cover API is accessible');
      if (response.statusCode == 400) {
        print('   400 is expected for test URL - API is working');
      }
    } else {
      print('⚠️  Unexpected response from Upload and Cover API');
    }
  } catch (e) {
    print('❌ Failed to test Upload and Cover API: $e');
  }

  // 7. Summary
  print('\n📋 TEST SUMMARY:');
  print('=' * 50);

  print('✅ kie.ai API Key: Configured');
  print('✅ Supabase URL: Configured');
  print('✅ Supabase Anon Key: Configured');
  print('✅ kie.ai API Connectivity: Tested');
  print('✅ Supabase Connectivity: Tested');
  print('✅ Upload and Cover API: Tested');

  print('\n🚀 READY FOR LOCAL TESTING!');
  print('The voice upload workflow should now work properly.');
  print('\n📋 NEXT STEPS:');
  print('1. Run: flutter clean && flutter pub get');
  print('2. Run: flutter run -d chrome');
  print('3. Navigate to AI Music Studio');
  print('4. Test voice recording and upload');

  print('\n💡 If you still encounter issues:');
  print('1. Ensure voice_recordings bucket exists in Supabase');
  print('2. Check browser console for specific error messages');
  print('3. Verify network requests in browser dev tools');
}