import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _buildPages(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 1 ? _buildFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  List<Widget> _buildPages() {
    return [
      // Radio Page
      Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const RadioTab(),
          );
        },
      ),

      // AI Music Studio Page
      Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const AiMusicTab(),
          );
        },
      ),

      // Chat Tab
      const Center(
        child: Text(
          'Chat\nComing Soon',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline4,
        ),
      ),

      // Profile Tab
      const Center(
        child: Text(
          'Profile\nComing Soon',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline4,
        ),
      ),
    ];
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radio_rounded),
              label: 'Radio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note_rounded),
              label: 'AI Music',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GlassFab(
      onPressed: () {
        context.go('/ai-music');
      },
      icon: Icons.add_rounded,
      tooltip: 'Create Music',
    );
  }
}

// Tab widgets for better organization
class RadioTab extends StatelessWidget {
  const RadioTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Radio Player\nComing Soon',
        textAlign: TextAlign.center,
        style: AppTextStyles.headline4,
      ),
    );
  }
}

class AiMusicTab extends StatelessWidget {
  const AiMusicTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'AI Music Studio\nComing Soon',
        textAlign: TextAlign.center,
        style: AppTextStyles.headline4,
      ),
    );
  }
}