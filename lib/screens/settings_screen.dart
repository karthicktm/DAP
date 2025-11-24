import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/secure_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _kieAiController = TextEditingController();
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showKieAiKey = false;
  bool _showSupabaseKey = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _kieAiController.text = settings.kieAiKey ?? '';
      _supabaseUrlController.text = settings.supabaseUrl ?? '';
      _supabaseKeyController.text = settings.supabaseKey ?? '';
    });
  }

  @override
  void dispose() {
    _kieAiController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1A1B3A),
        elevation: 0,
        actions: [
          if (settings.isFullyConfigured)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _showConfigurationSuccess(),
            ),
        ],
      ),
      body: settings.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Status Card
                  _buildStatusCard(settings),

                  // Configuration Section
                  _buildConfigurationSection(settings, settingsNotifier),

                  // Actions Section
                  _buildActionsSection(settings, settingsNotifier),

                  // Test Section
                  if (settings.isFullyConfigured)
                    _buildTestSection(settingsNotifier),

                  if (settings.hasError)
                    _buildErrorCard(settings.error!),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(SettingsState settings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.isFullyConfigured
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                settings.isFullyConfigured ? Icons.verified : Icons.warning,
                color: settings.isFullyConfigured ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Configuration Status',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                settings.isFullyConfigured ? 'Complete' : 'Incomplete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: settings.isFullyConfigured ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusItem('Kie.ai API', settings.configurationStatus['kie_ai'] ?? false),
          _buildStatusItem('Supabase URL', settings.configurationStatus['supabase_url'] ?? false),
          _buildStatusItem('Supabase Key', settings.configurationStatus['supabase_key'] ?? false),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isConfigured) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isConfigured ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isConfigured ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            isConfigured ? 'Configured' : 'Not Set',
            style: TextStyle(
              color: isConfigured ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection(SettingsState settings, SettingsNotifier settingsNotifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.key,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Kie.ai API Key',
            description: settings.kieAiKey?.isNotEmpty == true
                ? '••••••••••••••••${settings.kieAiKey!.substring(settings.kieAiKey!.length - 4)}'
                : 'Not configured',
            onTap: () => _showKieAiDialog(settingsNotifier),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.storage,
            iconColor: const Color(0xFF14B8A6),
            title: 'Supabase Configuration',
            description: 'URL and Anonymous Key',
            onTap: () => _showSupabaseDialog(settingsNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildActionsSection(SettingsState settings, SettingsNotifier settingsNotifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: settings.isFullyConfigured ? null : () => _showQuickSetupDialog(settingsNotifier),
              icon: const Icon(Icons.bolt),
              label: Text(settings.isFullyConfigured ? '✓ Configured' : 'Quick Setup'),
              style: FilledButton.styleFrom(
                backgroundColor: settings.isFullyConfigured ? Colors.green : const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (!settings.isFullyConfigured) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showSetupInstructions(),
              icon: const Icon(Icons.help_outline),
              label: const Text('Setup Instructions'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestSection(SettingsNotifier settingsNotifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1A1B3A),
        child: ListTile(
          leading: const Icon(Icons.bug_report, color: Color(0xFF14B8A6)),
          title: const Text('Test Configuration'),
          subtitle: const Text('Verify API connections'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _testConfiguration(settingsNotifier),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => ref.read(settingsProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }

  void _showKieAiDialog(SettingsNotifier settingsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          'Kie.ai API Key',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _kieAiController,
            obscureText: !_showKieAiKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter your Kie.ai API key',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
              suffixIcon: IconButton(
                icon: Icon(_showKieAiKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showKieAiKey = !_showKieAiKey),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an API key';
              }
              if (!SecureStorageService.isValidKieAiKey(value)) {
                return 'Invalid API key format';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final success = await settingsNotifier.updateKieAiKey(_kieAiController.text);
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kie.ai API key saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSupabaseDialog(SettingsNotifier settingsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          'Supabase Configuration',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _supabaseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Supabase URL',
                    hintText: 'https://your-project.supabase.co',
                    labelStyle: TextStyle(color: Color(0xFF14B8A6)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14B8A6)),
                    ),
                    prefixIcon: Icon(Icons.link, color: Color(0xFF14B8A6)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Supabase URL';
                    }
                    if (!SecureStorageService.isValidSupabaseUrl(value)) {
                      return 'Invalid URL format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _supabaseKeyController,
                  obscureText: !_showSupabaseKey,
                  decoration: InputDecoration(
                    labelText: 'Anonymous Key',
                    hintText: 'Enter your Supabase anon key',
                    labelStyle: const TextStyle(color: Color(0xFF14B8A6)),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF14B8A6)),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF14B8A6)),
                    suffixIcon: IconButton(
                      icon: Icon(_showSupabaseKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showSupabaseKey = !_showSupabaseKey),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter anon key';
                    }
                    if (!SecureStorageService.isValidSupabaseKey(value)) {
                      return 'Invalid key format';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF14B8A6))),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final success = await settingsNotifier.updateSupabaseCredentials(
                  _supabaseUrlController.text,
                  _supabaseKeyController.text,
                );
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supabase configuration saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showQuickSetupDialog(SettingsNotifier settingsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          'Quick Setup Guide',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔑 Kie.ai API Key',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Sign up at kie.ai\n2. Get your API key from dashboard\n3. Enter the key in settings',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                '🗄️ Supabase Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14B8A6),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Create account at supabase.com\n2. Create a new project\n3. Copy URL and anon key\n4. Enter both in settings',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showSetupInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          'Setup Instructions',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🚀 Getting Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'To use AI Radio Platform, you need:\n\n'
                '1. Kie.ai Account\n'
                '   • Sign up at https://kie.ai\n'
                '   • Get API key from dashboard\n'
                '   • Cost-effective AI services\n\n'
                '2. Supabase Account\n'
                '   • Sign up at https://supabase.com\n'
                '   • Create a new project\n'
                '   • Get URL and anon key\n'
                '   • Free tier available\n\n'
                '💡 Pro Tip:\n'
                'Both services have generous free tiers perfect for development!',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Start Setup'),
          ),
        ],
      ),
    );
  }

  void _showConfigurationSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          '🎉 Configuration Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'All services are configured and ready to use!\n\n'
              'You can now:\n'
              '• Generate AI music with Kie.ai\n'
              '• Store data with Supabase\n'
              '• Access all platform features',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _testConfiguration(SettingsNotifier settingsNotifier) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1A1B3A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Testing configuration...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    final results = await settingsNotifier.testConfiguration();

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1B3A),
          title: const Text(
            'Test Results',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: results.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value.contains('valid') ? Icons.check_circle : Icons.error,
                    color: entry.value.contains('valid') ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: entry.value.contains('valid') ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}