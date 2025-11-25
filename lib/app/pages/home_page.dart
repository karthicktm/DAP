import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/hero_section.dart';
import '../../widgets/feature_cards.dart';
import '../theme/colors.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: HeroSection(
              onGetStarted: () {
                // Navigate to AI Music Studio
                context.go('/ai-music');
              },
              onWatchDemo: () {
                _scrollToFeatures();
              },
            ),
          ),

          // Features Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF0F0F23),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Section Title
                  Text(
                    'Powerful Features',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 768 ? 48 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Everything you need for the ultimate audio experience',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 768 ? 20 : 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Feature Grid
                  FeatureGrid(
                    features: AppFeatureCards.defaultFeatures.map((feature) {
                      return FeatureCardData(
                        title: feature.title,
                        description: feature.description,
                        icon: feature.icon,
                        gradientColors: feature.gradientColors,
                        onTap: () => _handleFeatureTap(feature.title),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // Animated Stats
                  const AnimatedStats(),

                  const SizedBox(height: 80),

                  // Call to Action Section
                  _buildCtaSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready to Create Amazing Music?',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Join thousands of creators using our AI-powered platform',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.go('/ai-music');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Creating',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),

              if (isTablet) ...[
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () {
                    // Navigate to radio section
                    DefaultTabController.of(context)?.animateTo(1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radio, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Listen to Radio',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToFeatures() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height * 0.8,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleFeatureTap(String featureTitle) {
    switch (featureTitle) {
      case 'AI Music Generation':
        context.go('/ai-music');
        break;
      case 'Live Radio Streaming':
        // Navigate to radio tab - this would need to be handled by parent navigator
        break;
      case 'Real-time Chat':
        // Navigate to chat tab
        break;
      default:
        // Show coming soon dialog
        _showComingSoonDialog(featureTitle);
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          feature,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This feature is coming soon! Stay tuned for updates.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}