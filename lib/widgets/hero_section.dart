import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../app/theme/colors.dart';

class HeroSection extends StatefulWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onWatchDemo;

  const HeroSection({
    Key? key,
    this.onGetStarted,
    this.onWatchDemo,
  }) : super(key: key);

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animations
    _mainController.forward();
    _floatingController.repeat();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Container(
      height: size.height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          // Animated Background Effects
          _buildAnimatedBackground(),

          // Floating Elements
          _buildFloatingElements(),

          // Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 60 : 24,
                vertical: 40,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Left Content
                        Expanded(
                          flex: isTablet ? 1 : 1,
                          child: _buildMainContent(isTablet),
                        ),

                        if (isTablet) ...[
                          const SizedBox(width: 60),
                          // Right Visual
                          Expanded(
                            flex: 1,
                            child: _buildHeroVisual(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!isTablet)
                    SizedBox(
                      height: size.height * 0.4,
                      child: _buildHeroVisual(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return CustomPaint(
            painter: BackgroundEffectsPainter(
              animation: _floatingController,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating music notes
        ...List.generate(5, (index) {
          return Positioned(
            left: 50.0 + (index * 100),
            top: 100.0 + (index * 80),
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = Offset(
                  20 * (1 + 0.5 * index) *
                    Curves.easeInOut.transform(
                      (_floatingController.value + index * 0.2) % 1.0
                    ),
                  15 * Curves.easeInOut.transform(
                    (_floatingController.value + index * 0.3) % 1.0
                  ),
                );

                return Transform.translate(
                  offset: offset,
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGradient[index % 3],
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGradient[index % 3]
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainContent(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          'AI Radio Platform',
          style: TextStyle(
            fontSize: isTablet ? 64 : 42,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        )
          .animate()
          .fadeIn(duration: 800.ms, delay: 200.ms)
          .slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        // Subtitle
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.buttonGradient,
          ).createShader(bounds),
          child: Text(
            'Generate. Stream. Connect.',
            style: TextStyle(
              fontSize: isTablet ? 32 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        )
          .animate()
          .fadeIn(duration: 800.ms, delay: 400.ms)
          .slideX(begin: -0.3, end: 0),

        const SizedBox(height: 24),

        // Description
        Text(
          'Experience the future of music with AI-powered generation, live radio streaming, and real-time social features.',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        )
          .animate()
          .fadeIn(duration: 800.ms, delay: 600.ms)
          .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 40),

        // Feature Pills
        _buildFeaturePills()
          .animate()
          .fadeIn(duration: 800.ms, delay: 800.ms)
          .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 40),

        // Action Buttons
        _buildActionButtons(isTablet)
          .animate()
          .fadeIn(duration: 800.ms, delay: 1000.ms)
          .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      {'icon': '🎵', 'text': 'AI Music Generation'},
      {'icon': '📻', 'text': 'Live Radio'},
      {'icon': '💬', 'text': 'Real-time Chat'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feature['icon']!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                feature['text']!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      children: [
        // Primary Button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + 0.05 * Curves.easeInOut.transform(
              _pulseController.value
            );

            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.buttonGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onGetStarted,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 20),

        // Secondary Button
        GlassmorphicContainer(
          width: 140,
          height: 50,
          borderRadius: 25,
          blur: 10,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            colors: [
              AppColors.glassBackground.withOpacity(0.1),
              AppColors.glassBackground.withOpacity(0.05),
            ],
          ),
          borderGradient: const LinearGradient(
            colors: [AppColors.glassBorder, Colors.transparent],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onWatchDemo,
              borderRadius: BorderRadius.circular(25),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Demo',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return Center(
      child: Container(
        width: 400,
        height: 400,
        child: Stack(
          children: [
            // Main Video-like Container (similar to HTML component)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: AudioVisualizationPainter(
                              animation: _mainController,
                            ),
                          );
                        },
                      ),
                    ),

                    // Content overlay
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Play button
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + 0.1 * Curves.easeInOut.transform(
                                _pulseController.value
                              );

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'Experience the Magic',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'AI • Radio • Social',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
              .animate()
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
              .fadeIn(duration: 1200.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background effects
class BackgroundEffectsPainter extends CustomPainter {
  final Animation<double> animation;

  BackgroundEffectsPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create animated gradient circles
    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i * 0.3) % 1.0;
      final radius = size.width * 0.3 * progress;
      final opacity = (1.0 - progress) * 0.1;

      paint.color = AppColors.primaryGradient[i].withOpacity(opacity);

      canvas.drawCircle(
        Offset(
          size.width * (0.2 + i * 0.3),
          size.height * (0.3 + i * 0.2),
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for audio visualization
class AudioVisualizationPainter extends CustomPainter {
  final Animation<double> animation;

  AudioVisualizationPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw audio wave lines
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final waveHeight = size.height * 0.1;
      final waveSpeed = animation.value * 2 * 3.14159 + i * 0.5;

      paint.color = AppColors.audioWavePrimary.withOpacity(0.3);

      for (double x = 0; x < size.width; x += 5) {
        final y = size.height * 0.5 +
                 waveHeight * (i + 1) * 0.3 *
                 math.sin((x / size.width * 4 * 3.14159) + waveSpeed);

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}