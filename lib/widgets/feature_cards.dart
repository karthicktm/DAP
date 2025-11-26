import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../app/theme/colors.dart';

class FeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Duration? animationDelay;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.onTap,
    this.animationDelay,
  }) : super(key: key);

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final scale = 1.0 + _hoverController.value * 0.02;
            final elevation = _hoverController.value * 8;

            return Transform.scale(
              scale: scale,
              child: Container(
                height: 200,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withOpacity(0.2 + elevation * 0.02),
                      blurRadius: 20 + elevation,
                      offset: Offset(0, 8 + elevation),
                    ),
                  ],
                ),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 20,
                  blur: 15,
                  alignment: Alignment.center,
                  border: _isHovered ? 2 : 1,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.glassBackground.withOpacity(0.15),
                      AppColors.glassBackground.withOpacity(0.05),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? widget.gradientColors
                        : [AppColors.glassBorder, Colors.transparent],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with gradient background
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientColors.first.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    )
      .animate()
      .fadeIn(duration: 600.ms, delay: widget.animationDelay ?? 0.ms)
      .slideY(begin: 0.3, end: 0);
  }
}

class FeatureGrid extends StatelessWidget {
  final List<FeatureCardData> features;

  const FeatureGrid({
    Key? key,
    required this.features,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final crossAxisCount = isTablet ? 3 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isTablet ? 1.1 : 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureCard(
          title: feature.title,
          description: feature.description,
          icon: feature.icon,
          gradientColors: feature.gradientColors,
          onTap: feature.onTap,
          animationDelay: Duration(milliseconds: index * 200),
        );
      },
    );
  }
}

class FeatureCardData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  FeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });
}

// Pre-defined feature cards for the AI Radio Platform
class AppFeatureCards {
  static List<FeatureCardData> get defaultFeatures => [
    FeatureCardData(
      title: 'AI Music Generation',
      description: 'Create unique tracks with advanced AI technology',
      icon: Icons.music_note,
      gradientColors: AppColors.primaryGradient,
    ),
    FeatureCardData(
      title: 'Live Radio Streaming',
      description: 'Broadcast and listen to live radio stations with HD quality',
      icon: Icons.radio,
      gradientColors: AppColors.secondaryGradient,
    ),
    FeatureCardData(
      title: 'Real-time Chat',
      description: 'Connect with listeners through instant messaging and reactions',
      icon: Icons.chat_bubble,
      gradientColors: [AppColors.accent, AppColors.accentLight],
    ),
    FeatureCardData(
      title: 'Audio Visualization',
      description: 'Experience music with stunning real-time visual effects',
      icon: Icons.graphic_eq,
      gradientColors: [AppColors.audioWavePrimary, AppColors.audioWaveSecondary],
    ),
    FeatureCardData(
      title: 'Social Features',
      description: 'Share, like, and discover music with the community',
      icon: Icons.people,
      gradientColors: [AppColors.success, AppColors.secondary],
    ),
    FeatureCardData(
      title: 'Smart Playlists',
      description: 'AI-curated playlists based on your taste and mood',
      icon: Icons.playlist_play,
      gradientColors: [AppColors.warning, AppColors.accent],
    ),
  ];
}

// Animated stats widget for the hero section
class AnimatedStats extends StatefulWidget {
  const AnimatedStats({Key? key}) : super(key: key);

  @override
  State<AnimatedStats> createState() => _AnimatedStatsState();
}

class _AnimatedStatsState extends State<AnimatedStats>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<int>> _animations;

  final List<Map<String, dynamic>> _stats = [
    {'value': 10000, 'label': 'Active Users', 'icon': Icons.people},
    {'value': 5000, 'label': 'Generated Tracks', 'icon': Icons.library_music},
    {'value': 50, 'label': 'Live Stations', 'icon': Icons.radio},
    {'value': 24, 'label': 'Hours Daily', 'icon': Icons.access_time},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animations = _stats.map((stat) {
      return Tween<int>(
        begin: 0,
        end: stat['value'] as int,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ));
    }).toList();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: isTablet ? 120 : 200,
        borderRadius: 20,
        blur: 15,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isTablet
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildStatItems(),
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItems()[0],
                        _buildStatItems()[1],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItems()[2],
                        _buildStatItems()[3],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    )
      .animate()
      .fadeIn(duration: 800.ms, delay: 1200.ms)
      .slideY(begin: 0.3, end: 0);
  }

  List<Widget> _buildStatItems() {
    return List.generate(_stats.length, (index) {
      final stat = _stats[index];
      return AnimatedBuilder(
        animation: _animations[index],
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stat['icon'],
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                _formatNumber(_animations[index].value),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['label'],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      );
    });
  }
}