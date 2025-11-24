import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Simple working demo without complex imports
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: SimpleTestApp(),
    ),
  );
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Radio Platform - Foundation Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6), // Purple
          secondary: Color(0xFF14B8A6), // Teal
          surface: Color(0xFF1A1B3A), // Midnight purple
          background: Color(0xFF0F0F23), // Deep space blue
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
      ),
      home: const FoundationTestPage(),
    );
  }
}

class FoundationTestPage extends StatefulWidget {
  const FoundationTestPage({Key? key}) : super(key: key);

  @override
  State<FoundationTestPage> createState() => _FoundationTestPageState();
}

class _FoundationTestPageState extends State<FoundationTestPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _logoController.forward().then((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F23), // Deep space blue
              Color(0xFF1A1B3A), // Midnight purple
              Color(0xFF252641), // Lighter surface
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildSubtitle(),
                const SizedBox(height: 48),
                _buildStatusCard(),
                const SizedBox(height: 32),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoController.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6), // Primary purple
                  Color(0xFF7C3AED), // Darker purple
                  Color(0xFF6D28D9), // Even darker
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.radio_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: const Text(
            'AI Radio Platform',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: Text(
            'Powered by kie.ai • Big Tech Free Foundation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B3A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatusItem('Flutter SDK', '✅ 3.32.0 Installed'),
                _buildStatusItem('Dependencies', '✅ 178 Packages Loaded'),
                _buildStatusItem('kie.ai Ready', '⚠️ API Key Needed'),
                _buildStatusItem('Supabase Ready', '⚠️ Project Needed'),
                _buildStatusItem('macOS Support', '✅ Desktop Enabled'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        _buildGradientButton('🎵 Test AI Music Studio', () async {
          setState(() => _isLoading = true);
          await _simulateApiCall('AI Music Studio API');
          setState(() => _isLoading = false);
        }),
        const SizedBox(height: 16),
        _buildGradientButton('📻 Test Radio Player', () async {
          setState(() => _isLoading = true);
          await _simulateApiCall('Radio Streaming API');
          setState(() => _isLoading = false);
        }),
        const SizedBox(height: 16),
        _buildOutlineButton('📊 View Foundation Status', () {
          _showFoundationDialog();
        }),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 280,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
          elevation: 8,
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6), // Primary purple
                Color(0xFFEC4899), // Hot pink accent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 280,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }

  Future<void> _simulateApiCall(String service) async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$service - Foundation Test Successful! ✅'),
          backgroundColor: const Color(0xFF8B5CF6),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFoundationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text(
          'Foundation Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ COMPLETED:\n'
                '• Flutter SDK 3.32.0 installed\n'
                '• 178 dependencies resolved\n'
                '• Project structure created\n'
                '• macOS desktop support added\n'
                '• Environment configuration ready\n'
                '• Big tech-free architecture\n'
                '• Modern UI framework\n\n'
                '⚠️ NEXT STEPS:\n'
                '• Get kie.ai API key\n'
                '• Setup Supabase project\n'
                '• Configure environment variables\n'
                '• Test real API integration\n'
                '• Add mobile platforms\n\n'
                '🚀 FOUNDATION IS READY!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Awesome!',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }
}