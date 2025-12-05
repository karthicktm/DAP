// Create voice_recordings bucket in Supabase
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🪣 Creating voice_recordings bucket in Supabase...\n');

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
  final supabaseServiceKey = envVars['SUPABASE_ANON_KEY'] ?? ''; // For now, use anon key

  print('Using URL: $supabaseUrl');

  // Create bucket using storage API
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': 'voice_recordings',
        'name': 'voice_recordings',
        'public': false,
        'file_size_limit': 52428800, // 50MB
        'allowed_mime_types': ['audio/webm', 'audio/m4a', 'audio/mp3', 'audio/wav'],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ voice_recordings bucket created successfully');
      print('Response: ${response.body}');
    } else if (response.statusCode == 409) {
      print('✅ voice_recordings bucket already exists');
    } else {
      print('⚠️  Failed to create bucket: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error creating bucket: $e');
  }

  // Check if bucket exists
  print('\n🔍 Checking if bucket exists...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/voice_recordings'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('✅ voice_recordings bucket exists and is accessible');
      final bucketData = jsonDecode(response.body);
      print('Bucket details: ${bucketData['name']}');
    } else {
      print('⚠️  Bucket check failed: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error checking bucket: $e');
  }

  print('\n📋 MANUAL SETUP INSTRUCTIONS:');
  print('If the automatic bucket creation failed, you can create it manually:');
  print('1. Go to https://supabase.com/dashboard');
  print('2. Navigate to your project');
  print('3. Go to Storage > Buckets');
  print('4. Click "New bucket"');
  print('5. Enter:');
  print('   - Name: voice_recordings');
  print('   - Public bucket: false');
  print('   - File size limit: 52428800 (50MB)');
  print('6. Save the bucket');
  print('7. Click on the bucket and go to Settings');
  print('8. Add RLS policy to allow uploads:');
  print('   ```sql');
  print('   CREATE POLICY "Users can upload voice recordings" ON storage.objects');
  print('   FOR INSERT WITH CHECK (bucket_id = \'voice_recordings\');');
  print('   ```');
}