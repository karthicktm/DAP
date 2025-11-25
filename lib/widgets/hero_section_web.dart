import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme/colors.dart';

class HeroSectionWeb extends StatefulWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onWatchDemo;

  const HeroSectionWeb({
    Key? key,
    this.onGetStarted,
    this.onWatchDemo,
  }) : super(key: key);

  @override
  State<HeroSectionWeb> createState() => _HeroSectionWebState();
}

class _HeroSectionWebState extends State<HeroSectionWeb>
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
    final isMobile = size.width < 600;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: size.height,
      ),
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
                horizontal: isMobile ? 16 : (isTablet ? 60 : 32),
                vertical: isMobile ? 20 : 40,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isTablet) {
                    // Desktop/Tablet Layout
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Content
                        Expanded(
                          flex: 3,
                          child: _buildMainContent(isTablet, isMobile),
                        ),

                        const SizedBox(width: 40),

                        // Right Visual
                        Expanded(
                          flex: 2,
                          child: _buildHeroVisual(isTablet, isMobile),
                        ),
                      ],
                    );
                  } else {
                    // Mobile Layout
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.05),

                          // Hero Visual First on Mobile
                          Container(
                            height: size.height * 0.35,
                            child: _buildHeroVisual(isTablet, isMobile),
                          ),

                          const SizedBox(height: 32),

                          // Main Content Below on Mobile
                          _buildMainContent(isTablet, isMobile),

                          SizedBox(height: size.height * 0.1),
                        ],
                      ),
                    );
                  }
                },
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

  Widget _buildMainContent(bool isTablet, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          'AI Radio Platform',
          style: TextStyle(
            fontSize: isMobile ? 36 : (isTablet ? 64 : 48),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        )
          .animate()
          .fadeIn(duration: 800.ms, delay: 200.ms)
          .slideX(begin: -0.3, end: 0),

        SizedBox(height: isMobile ? 12 : 16),

        // Subtitle
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.buttonGradient,
          ).createShader(bounds),
          child: Text(
            'Generate. Stream. Connect.',
            style: TextStyle(
              fontSize: isMobile ? 20 : (isTablet ? 32 : 24),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
          ),
        )
          .animate()
          .fadeIn(duration: 800.ms, delay: 400.ms)
          .slideX(begin: -0.3, end: 0),

        SizedBox(height: isMobile ? 16 : 24),

        // Description
        Text(
          'Experience the future of music with AI-powered generation, live radio streaming, and real-time social features.',
          style: TextStyle(
            fontSize: isMobile ? 14 : (isTablet ? 18 : 16),
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
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
        _buildActionButtons(isTablet, isMobile)
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

  Widget _buildActionButtons(bool isTablet, bool isMobile) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
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

        SizedBox(
          width: isMobile ? 0 : 20,
          height: isMobile ? 16 : 0,
        ),

        // Secondary Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onWatchDemo,
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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

  Widget _buildHeroVisual(bool isTablet, bool isMobile) {
    final visualSize = isMobile ? 280.0 : (isTablet ? 400.0 : 350.0);

    return Center(
      child: Container(
        width: visualSize,
        height: visualSize,
        child: Stack(
          children: [
            // Main Visual Container (similar to HTML video component)
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

                              final buttonSize = isMobile ? 60.0 : 80.0;

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: buttonSize,
                                  height: buttonSize,
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
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    size: isMobile ? 30 : 40,
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