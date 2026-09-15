import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterprojects/features/splash/views/splash_screen.dart';
import 'package:flutterprojects/features/onboarding/views/onboarding_screen.dart';
import 'package:flutterprojects/features/auth/views/login_screen.dart';
import 'package:flutterprojects/features/home_curation/views/home_screen.dart';
import 'package:flutterprojects/features/home_curation/views/main_shell.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';
import 'package:flutterprojects/features/map_search/views/map_screen.dart';
import 'package:flutterprojects/features/saved/views/saved_screen.dart';
import 'package:flutterprojects/features/my_history/views/my_history_screen.dart';
import 'package:flutterprojects/features/my_history/views/receipt_share_screen.dart';
import 'package:flutterprojects/features/my_history/views/stamp_history_screen.dart';
import 'package:flutterprojects/features/my_history/views/stamp_share_preview_screen.dart';
import 'package:flutterprojects/features/travel_preferences/views/travel_preferences_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const TravelPreferencesScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const MapScreen()),
        ),
        GoRoute(
          path: '/map/route',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: MapScreen(
              key: ValueKey(state.extra),
              initialRoute: state.extra is SelectedRoute
                  ? state.extra! as SelectedRoute
                  : null,
            ),
          ),
        ),
        GoRoute(
          path: '/saved',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const SavedScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const MyHistoryScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/history/receipt',
      builder: (context, state) => const ReceiptShareScreen(),
    ),
    GoRoute(
      path: '/history/stamps',
      builder: (context, state) => const StampHistoryScreen(),
    ),
    GoRoute(
      path: '/history/stamp-preview',
      builder: (context, state) => const StampSharePreviewScreen(),
    ),
  ],
);
