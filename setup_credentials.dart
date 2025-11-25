#!/usr/bin/env dart
// Quick credential setup script for local testing
// Run with: dart setup_credentials.dart

import 'dart:io';

void main() async {
  print('🔐 kie.ai v5 Credential Setup for Local Testing');
  print('=' * 60);
  print('This script will help you set up credentials for testing.');
  print('Choose your preferred method:\n');

  print('1. 🌍 Environment Variables (recommended for security)');
  print('2. 📱 Flutter App Storage (persists in app)');
  print('3. 📄 Create .env file (for development)');
  print('4. ❌ Exit');

  stdout.write('\nChoose option (1-4): ');
  final choice = stdin.readLineSync() ?? '';

  switch (choice) {
    case '1':
      await setupEnvironmentVariables();
      break;
    case '2':
      await setupAppStorage();
      break;
    case '3':
      await createEnvFile();
      break;
    case '4':
      print('👋 Exiting...');
      return;
    default:
      print('❌ Invalid choice. Exiting...');
      return;
  }

  print('\n✅ Setup complete! You can now run the tests.');
  print('📚 Check TEST_LOCAL_V5.md for detailed testing instructions.');
}

Future<void> setupEnvironmentVariables() async {
  print('\n🌍 Setting up Environment Variables');
  print('-' * 40);

  final credentials = await getCredentials();

  print('\n📋 Add these to your shell profile (~/.bashrc, ~/.zshrc, etc.):');
  print('');
  print('export KIE_AI_API_KEY="${credentials['kieAi']}"');
  print('export SUPABASE_URL="${credentials['supabaseUrl']}"');
  print('export SUPABASE_ANON_KEY="${credentials['supabaseKey']}"');
  print('');
  print('Then run: source ~/.bashrc (or ~/.zshrc)');
  print('');
  print('💡 Or run tests with:');
  print('KIE_AI_API_KEY="${credentials['kieAi']}" \\');
  print('SUPABASE_URL="${credentials['supabaseUrl']}" \\');
  print('SUPABASE_ANON_KEY="${credentials['supabaseKey']}" \\');
  print('flutter run');
}

Future<void> setupAppStorage() async {
  print('\n📱 App Storage Setup');
  print('-' * 40);
  print('⚠️ This requires running in the Flutter app context.');
  print('');

  final credentials = await getCredentials();

  print('Add this code to your Flutter app and run it once:');
  print('');
  print('```dart');
  print('import "lib/services/secure_storage_service.dart";');
  print('');
  print('// Add to your main() or a setup method:');
  print('await SecureStorageService.setKieAiKey("${credentials['kieAi']}");');
  print('await SecureStorageService.setSupabaseUrl("${credentials['supabaseUrl']}");');
  print('await SecureStorageService.setSupabaseKey("${credentials['supabaseKey']}");');
  print('```');
  print('');
  print('💡 The credentials will be saved securely in the app.');
}

Future<void> createEnvFile() async {
  print('\n📄 Creating .env File');
  print('-' * 40);

  final credentials = await getCredentials();

  try {
    final envContent = '''# kie.ai v5 Testing Environment Variables
# Generated on ${DateTime.now()}

KIE_AI_API_KEY=${credentials['kieAi']}
SUPABASE_URL=${credentials['supabaseUrl']}
SUPABASE_ANON_KEY=${credentials['supabaseKey']}

# Local webhook URL for testing
WEBHOOK_URL=http://localhost:8080/api/webhook/music
''';

    await File('.env').writeAsString(envContent);
    print('✅ Created .env file in project root');
    print('');
    print('⚠️ Make sure .env is in your .gitignore file!');
    print('');
    print('To use with flutter_dotenv:');
    print('1. Add flutter_dotenv to pubspec.yaml');
    print('2. Load in main(): await dotenv.load(fileName: ".env");');

    // Also add to gitignore if it exists
    final gitignore = File('.gitignore');
    if (await gitignore.exists()) {
      final content = await gitignore.readAsString();
      if (!content.contains('.env')) {
        await gitignore.writeAsString('$content\n# Environment variables\n.env\n');
        print('3. Added .env to .gitignore');
      }
    }

  } catch (e) {
    print('❌ Failed to create .env file: $e');
  }
}

Future<Map<String, String>> getCredentials() async {
  print('\n📋 Enter your credentials:');
  print('(They will be masked for security)\n');

  stdout.write('🔑 kie.ai API Key: ');
  final kieAi = _readPassword();

  stdout.write('🗄️  Supabase URL (e.g., https://xxx.supabase.co): ');
  final supabaseUrl = stdin.readLineSync() ?? '';

  stdout.write('🔐 Supabase Anon Key: ');
  final supabaseKey = _readPassword();

  return {
    'kieAi': kieAi,
    'supabaseUrl': supabaseUrl,
    'supabaseKey': supabaseKey,
  };
}

String _readPassword() {
  // Simple password reading - for demo purposes, use regular input
  // In production, you'd want proper password masking
  return stdin.readLineSync() ?? '';
}