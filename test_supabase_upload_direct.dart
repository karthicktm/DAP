// Test Supabase upload directly to verify bucket and permissions
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() async {
  print('🗄️  TESTING SUPABASE UPLOAD DIRECTLY\n');

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

  final supabaseUrl = envVars['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'] ?? '';

  print('✅ Supabase URL: $supabaseUrl');
  print('✅ Anon Key: ${supabaseAnonKey.substring(0, 20)}...');

  // Test 1: Check if bucket exists (with proper headers)
  print('\n📦 Step 1: Check bucket existence...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/voice_recordings'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Accept': 'application/json',
      },
    );

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');

    if (response.statusCode == 200) {
      print('   ✅ Bucket exists and is accessible!');
    } else if (response.statusCode == 404) {
      print('   ❌ Bucket not found');
    } else {
      print('   ⚠️  Unexpected response: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Error checking bucket: $e');
  }

  // Test 2: List all buckets (to see what exists)
  print('\n📋 Step 2: List all storage buckets...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Accept': 'application/json',
      },
    );

    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final buckets = jsonDecode(response.body);
      print('   📋 Available buckets:');
      for (final bucket in buckets) {
        print('     - ${bucket['name']} (ID: ${bucket['id']})');
      }
    } else {
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Error listing buckets: $e');
  }

  // Test 3: Try to upload a test file (if bucket exists)
  print('\n📤 Step 3: Test file upload...');
  try {
    // Create a small test file
    final testData = Uint8List.fromList('Test audio file content'.codeUnits);
    final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
    final filePath = 'voice_recordings/$fileName';

    // Try to upload using REST API
    final uploadResponse = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/$filePath'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'text/plain',
      },
      body: testData,
    );

    print('   Upload Status: ${uploadResponse.statusCode}');
    print('   Upload Response: ${uploadResponse.body}');

    if (uploadResponse.statusCode == 200) {
      print('   ✅ Upload successful!');

      // Test 4: Try to create signed URL for the uploaded file
      print('\n🔗 Step 4: Test signed URL creation...');
      try {
        final signedResponse = await http.post(
          Uri.parse('$supabaseUrl/storage/v1/object/sign/$filePath'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'expiresIn': 3600}),
        );

        print('   Signed URL Status: ${signedResponse.statusCode}');
        if (signedResponse.statusCode == 200) {
          final signedData = jsonDecode(signedResponse.body);
          print('   ✅ Signed URL created: ${signedData['signedUrl']}');
        } else {
          print('   Signed URL Response: ${signedResponse.body}');
        }
      } catch (e) {
        print('   ❌ Error creating signed URL: $e');
      }
    } else {
      print('   ❌ Upload failed');
    }
  } catch (e) {
    print('   ❌ Error during upload test: $e');
  }

  print('\n📋 SUMMARY:');
  print('• If bucket listing shows voice_recordings, it exists');
  print('• If upload works, permissions are correct');
  print('• If you see 403/401 errors, check RLS policies');
  print('• If you see 404 errors, bucket might not exist');

  print('\n💡 TROUBLESHOOTING:');
  print('1. Check Supabase dashboard: Storage > Buckets');
  print('2. Verify bucket name is exactly "voice_recordings"');
  print('3. Check RLS policies in Settings > Policies');
  print('4. Try using service role key for bucket creation');
}