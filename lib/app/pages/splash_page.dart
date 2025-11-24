import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToMain();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start animations
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  void _navigateToMain() {
    // Navigate after animations complete
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Check authentication status
        // For now, go directly to main app
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              _buildAppName(),
              const SizedBox(height: 48),
              _buildLoadingIndicator(),
            ],
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
          )
              .animate()
              .scale(duration: 800.ms, curve: Curves.elasticOut)
              .rotate(duration: 600.ms, curve: Curves.easeInOut)
              .shimmer(duration: 1500.ms),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textController.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _textController.value)),
            child: Column(
              children: [
                Text(
                  'AI Radio',
                  style: AppTextStyles.displayMedium.copyWith(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: AppColors.buttonGradient,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Create, Listen, Connect',
                  style: AppTextStyles.bodyText1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 700.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.primary.withOpacity(0.8),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 1500.ms),
    );
  }
}