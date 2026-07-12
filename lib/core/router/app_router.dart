import 'package:go_router/go_router.dart';
import '../../features/splash/views/splash_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/home_curation/views/home_screen.dart';
import '../../features/map_search/views/map_screen.dart';
import '../../features/my_history/views/my_history_screen.dart';
import '../../features/saved/views/saved_screen.dart';
import '../../features/home_curation/views/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
        GoRoute(path: '/history', builder: (_, __) => const MyHistoryScreen()),
      ],
    ),
  ],
);
