import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/simple_glass_button.dart';

class SimpleTestPage extends ConsumerStatefulWidget {
  const SimpleTestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SimpleTestPage> createState() => _SimpleTestPageState();
}

class _SimpleTestPageState extends ConsumerState<SimpleTestPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;

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
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
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
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
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
          child: Text(
            'AI Radio Platform',
            style: AppTextStyles.headline3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
            'Powered by kie.ai • Big Tech Free',
            style: AppTextStyles.bodyText1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SimpleGlassButton(
          text: '🎵 AI Music Studio',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI Music Studio - Coming Soon!'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          width: 250,
        ),
        const SizedBox(height: 16),
        SimpleGlassButton(
          text: '📻 Radio Player',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Radio Player - Coming Soon!'),
                backgroundColor: AppColors.secondary,
              ),
            );
          },
          width: 250,
          backgroundColor: AppColors.secondary,
        ),
        const SizedBox(height: 16),
        SimpleGlassButton(
          text: '⚙️ Settings',
          onPressed: () {
            _showSettings();
          },
          width: 250,
          backgroundColor: AppColors.surface.withOpacity(0.3),
        ),
      ],
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Settings',
          style: AppTextStyles.headline6.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Environment Configuration',
              style: AppTextStyles.bodyText1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'kie.ai API: ${_getApiKeyStatus()}\n'
                'Supabase: ${_getSupabaseStatus()}\n'
                'Flutter SDK: ✅ Installed',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          SimpleGlassButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            width: 100,
          ),
        ],
      ),
    );
  }

  String _getApiKeyStatus() {
    // This would check the actual environment in a real app
    return '⚠️ Not configured';
  }

  String _getSupabaseStatus() {
    // This would check the actual environment in a real app
    return '⚠️ Not configured';
  }
}