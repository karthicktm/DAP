import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/ai_music/presentation/pages/ai_music_studio_page.dart';
import '../../features/radio/presentation/pages/radio_player_page.dart';
import '../pages/main_navigation_page.dart';
import '../pages/splash_page.dart';

// Provider for the router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInPage(),
      ),

      GoRoute(
        path: '/sign-up',
        name: 'sign-up',
        builder: (context, state) => const SignUpPage(),
      ),

      // Main App Navigation
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainNavigationPage(),
        routes: [
          // Radio Tab
          GoRoute(
            path: 'radio',
            name: 'radio',
            builder: (context, state) => const RadioPlayerPage(),
          ),

          // AI Music Studio Tab
          GoRoute(
            path: 'ai-music',
            name: 'ai-music',
            builder: (context, state) => const AiMusicStudioPage(),
          ),

          // Chat Tab (placeholder)
          GoRoute(
            path: 'chat',
            name: 'chat',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Chat - Coming Soon'),
              ),
            ),
          ),

          // Profile Tab (placeholder)
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Profile - Coming Soon'),
              ),
            ),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    redirect: (context, state) {
      // Add authentication logic here
      // For now, allow all routes
      return null;
    },
  );
});