import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.1),
        selectedIndex: _indexFromPath(location),
        onDestinationSelected: (i) {
          const paths = ['/home', '/map', '/saved', '/history'];
          context.go(paths[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '주변 콤보',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '찜',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '기록',
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/map')) return 1;
    if (path.startsWith('/saved')) return 2;
    if (path.startsWith('/history')) return 3;
    return 0;
  }
}
