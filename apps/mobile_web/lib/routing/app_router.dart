import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/category_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/local_mode_screen.dart';
import '../features/onboarding/profile_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/parent/gate_screen.dart';
import '../features/parent/parent_screens.dart';
import '../features/player/player_screen.dart';
import 'lock_on_show.dart';
import 'providers.dart';
import 'redirect.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final router = GoRouter(
    initialLocation: '/loading',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      return redirectFor(
        location: state.matchedLocation,
        sessionLoading: session.isLoading,
        hasProfile: session.asData?.value != null,
        gateUnlocked: ref.read(parentGateProvider),
      );
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/local',
        builder: (context, state) => const LocalModeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LockOnShow(child: HomeScreen()),
      ),
      GoRoute(
        path: '/c/:categoryId',
        builder: (context, state) => LockOnShow(
          child: CategoryScreen(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/a/:contentId',
        builder: (context, state) => LockOnShow(
          child: PlayerScreen(contentId: state.pathParameters['contentId']!),
        ),
      ),
      GoRoute(
        path: '/parent/gate',
        builder: (context, state) => const GateScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentHomeScreen(),
      ),
      GoRoute(
        path: '/parent/language',
        builder: (context, state) => const ParentLanguageScreen(),
      ),
      GoRoute(
        path: '/parent/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/parent/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('Little Genius'))),
    );
  }
}
