#!/usr/bin/env dart
// Local testing script for kie.ai v5 integration
// Run with: dart test_local_v5.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 kie.ai v5 Local Testing Script');
  print('=' * 50);

  // Get credentials from user
  final credentials = await getCredentials();

  if (!credentials['valid']) {
    print('❌ Invalid credentials provided. Exiting.');
    return;
  }

  print('\n🔧 Testing Configuration...');
  await testSupabaseConnection(credentials['supabaseUrl'], credentials['supabaseKey']);
  await testKieAiConnection(credentials['kieAiKey']);

  print('\n🎵 Starting v5 Music Generation Test...');
  await testMusicGeneration(credentials['kieAiKey'], credentials['webhookUrl']);

  print('\n✅ Local testing complete!');
  print('📋 Check the logs above for any issues.');
}

Future<Map<String, dynamic>> getCredentials() async {
  print('\n📋 Please provide your credentials:');

  stdout.write('🔑 kie.ai API Key: ');
  final kieAiKey = stdin.readLineSync() ?? '';

  stdout.write('🗄️ Supabase URL: ');
  final supabaseUrl = stdin.readLineSync() ?? '';

  stdout.write('🔐 Supabase Anon Key: ');
  final supabaseKey = stdin.readLineSync() ?? '';

  stdout.write('🌐 Webhook URL (or press Enter for localhost:8080): ');
  var webhookUrl = stdin.readLineSync() ?? '';

  if (webhookUrl.isEmpty) {
    webhookUrl = 'http://localhost:8080/api/webhook/music';
  }

  final valid = kieAiKey.isNotEmpty && supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  return {
    'kieAiKey': kieAiKey,
    'supabaseUrl': supabaseUrl,
    'supabaseKey': supabaseKey,
    'webhookUrl': webhookUrl,
    'valid': valid,
  };
}

Future<void> testSupabaseConnection(String url, String key) async {
  try {
    print('🗄️ Testing Supabase connection...');

    final response = await http.get(
      Uri.parse('$url/rest/v1/'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    );

    if (response.statusCode == 200) {
      print('✅ Supabase connection successful');
    } else {
      print('❌ Supabase connection failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Supabase connection error: $e');
  }
}

Future<void> testKieAiConnection(String apiKey) async {
  try {
    print('🎵 Testing kie.ai connection...');

    // Test with a simple API call (you might need to adjust endpoint)
    final response = await http.get(
      Uri.parse('https://api.kie.ai/api/v1/user/info'), // Adjust if needed
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('✅ kie.ai connection successful');
      final data = jsonDecode(response.body);
      print('   User info: $data');
    } else {
      print('❌ kie.ai connection failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ kie.ai connection error: $e');
  }
}

Future<void> testMusicGeneration(String apiKey, String webhookUrl) async {
  try {
    print('🎼 Testing v5 music generation...');

    final requestData = {
      'prompt': 'A calm relaxing piano melody for testing',
      'instrumental': true,
      'model': 'V5',
      'customMode': true,
      'style': 'Classical',
      'title': 'Test V5 Generation',
      'callBackUrl': webhookUrl,
      // v5 specific parameters
      'styleWeight': 0.65,
      'weirdnessConstraint': 0.5,
      'audioWeight': 0.5,
    };

    print('📤 Sending request with v5 parameters:');
    print(jsonEncode(requestData));

    final response = await http.post(
      Uri.parse('https://api.kie.ai/api/v1/generate'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    print('\n📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        final taskId = data['data']['taskId'];
        print('✅ Music generation started successfully!');
        print('🆔 Task ID: $taskId');
        print('🔔 Webhook URL: $webhookUrl');
        print('\n⏳ Now waiting for webhook callbacks...');
        print('   Expected callbacks: text → first → complete');
      } else {
        print('❌ API returned error: ${data['msg']}');
      }
    } else {
      print('❌ Music generation failed');
    }
  } catch (e) {
    print('❌ Music generation error: $e');
  }
}