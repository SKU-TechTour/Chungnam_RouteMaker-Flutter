import 'package:go_router/go_router.dart';
import 'package:flutterprojects/features/splash/views/splash_screen.dart';
import 'package:flutterprojects/features/onboarding/views/onboarding_screen.dart';
import 'package:flutterprojects/features/auth/views/login_screen.dart';
import 'package:flutterprojects/features/home_curation/views/home_screen.dart';
import 'package:flutterprojects/features/home_curation/views/main_shell.dart';
import 'package:flutterprojects/features/map_search/views/map_screen.dart';
import 'package:flutterprojects/features/saved/views/saved_screen.dart';
import 'package:flutterprojects/features/my_history/views/my_history_screen.dart';
import 'package:flutterprojects/features/my_history/views/receipt_share_screen.dart';
import 'package:flutterprojects/features/my_history/views/stamp_history_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const MyHistoryScreen(),
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
  ],
);
