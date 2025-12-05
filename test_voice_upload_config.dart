// Diagnostic test to identify voice upload configuration issues
import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('🔍 DIAGNOSTIC: Voice Upload Configuration Check\n');

  // 1. Load environment variables
  print('📁 Loading .env file...');
  try {
    await dotenv.load(fileName: '.env');
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    return;
  }

  // 2. Check kie.ai API key
  print('\n🔑 Checking kie.ai API key...');
  final kieApiKey = dotenv.env['KIE_AI_API_KEY'] ?? 'NOT_FOUND';
  if (kieApiKey == 'your_kie_ai_api_key_here' || kieApiKey == 'NOT_FOUND') {
    print('❌ kie.ai API key is not configured');
    print('   Please add your actual API key to .env file:');
    print('   KIE_AI_API_KEY=your_actual_api_key_here');
  } else {
    print('✅ kie.ai API key found: ${kieApiKey.substring(0, 10)}...');
  }

  // 3. Check Supabase configuration
  print('\n🗄️  Checking Supabase configuration...');
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'NOT_FOUND';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'NOT_FOUND';

  if (supabaseUrl == 'your_supabase_project_url' || supabaseUrl == 'NOT_FOUND') {
    print('❌ Supabase URL is not configured');
    print('   Please add your Supabase project URL to .env file:');
    print('   SUPABASE_URL=https://your-project-id.supabase.co');
  } else {
    print('✅ Supabase URL found: $supabaseUrl');
  }

  if (supabaseAnonKey == 'your_supabase_anon_key' || supabaseAnonKey == 'NOT_FOUND') {
    print('❌ Supabase Anon Key is not configured');
    print('   Please add your Supabase anon key to .env file:');
    print('   SUPABASE_ANON_KEY=your_supabase_anon_key_here');
  } else {
    print('✅ Supabase Anon Key found: ${supabaseAnonKey.substring(0, 20)}...');
  }

  // 4. Test kie.ai API connectivity
  print('\n🌐 Testing kie.ai API connectivity...');
  if (kieApiKey != 'your_kie_ai_api_key_here' && kieApiKey != 'NOT_FOUND') {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.kie.ai/api/v1'));
      request.headers.set('Authorization', 'Bearer $kieApiKey');
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      print('✅ kie.ai API responded with status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        print('✅ kie.ai API is accessible (401 means key is invalid but server is reachable)');
      } else {
        print('⚠️  Unexpected response from kie.ai API: ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      print('❌ Failed to connect to kie.ai API: $e');
    }
  } else {
    print('❌ Cannot test kie.ai API - key not configured');
  }

  // 5. Test Supabase connectivity
  print('\n🗄️  Testing Supabase connectivity...');
  if (supabaseUrl != 'your_supabase_project_url' && supabaseUrl != 'NOT_FOUND') {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      print('✅ Supabase API responded with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Supabase is accessible and properly configured');
      } else {
        print('⚠️  Unexpected response from Supabase: ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      print('❌ Failed to connect to Supabase: $e');
    }
  } else {
    print('❌ Cannot test Supabase - URL not configured');
  }

  // 6. Summary
  print('\n📋 SUMMARY OF REQUIRED CONFIGURATION:');
  print('=' * 50);

  if (kieApiKey == 'your_kie_ai_api_key_here' || kieApiKey == 'NOT_FOUND') {
    print('❌ NEED: kie.ai API Key');
    print('   Get it from: https://kie.ai/');
    print('   Add to .env: KIE_AI_API_KEY=your_actual_key');
  }

  if (supabaseUrl == 'your_supabase_project_url' || supabaseUrl == 'NOT_FOUND') {
    print('❌ NEED: Supabase Project URL');
    print('   Create project at: https://supabase.com/');
    print('   Add to .env: SUPABASE_URL=https://your-project.supabase.co');
  }

  if (supabaseAnonKey == 'your_supabase_anon_key' || supabaseAnonKey == 'NOT_FOUND') {
    print('❌ NEED: Supabase Anon Key');
    print('   Find in Supabase project settings > API');
    print('   Add to .env: SUPABASE_ANON_KEY=your_actual_anon_key');
  }

  if (kieApiKey != 'your_kie_ai_api_key_here' &&
      kieApiKey != 'NOT_FOUND' &&
      supabaseUrl != 'your_supabase_project_url' &&
      supabaseUrl != 'NOT_FOUND' &&
      supabaseAnonKey != 'your_supabase_anon_key' &&
      supabaseAnonKey != 'NOT_FOUND') {
    print('\n🎉 ALL CONFIGURATIONS ARE COMPLETE!');
    print('   The voice upload should work properly.');
  } else {
    print('\n⚠️  Some configurations are missing.');
    print('   Please provide the missing details and run this test again.');
  }

  print('\n🔧 NEXT STEPS:');
  print('1. Update .env file with missing configurations');
  print('2. Run "flutter clean && flutter pub get"');
  print('3. Restart the Flutter app');
  print('4. Test voice recording again');
}