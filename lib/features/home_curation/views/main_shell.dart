import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = _indexFromPath(location) == index;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.path),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected ? Colors.white : Colors.white54,
                          size: 21,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static const _items = [
    _NavItem('/home', '홈', Icons.home_outlined, Icons.home_rounded),
    _NavItem('/map', '주변 코스', Icons.near_me_outlined, Icons.near_me_rounded),
    _NavItem(
      '/saved',
      '찜',
      Icons.bookmark_border_rounded,
      Icons.bookmark_rounded,
    ),
    _NavItem(
      '/history',
      '내 정보',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  int _indexFromPath(String path) {
    if (path.startsWith('/map')) return 1;
    if (path.startsWith('/saved')) return 2;
    if (path.startsWith('/history')) return 3;
    return 0;
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
