import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('찜'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('편집', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: const _EmptyState(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline, size: 56, color: AppTheme.divider),
          const SizedBox(height: 16),
          const Text('찜한 코스가 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const Text('홈에서 마음에 드는 코스를 찜해보세요',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
