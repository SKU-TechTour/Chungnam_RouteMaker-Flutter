import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _saved = <_SavedCourse>[
    const _SavedCourse(
      '공주 감성 하루 코스',
      '공산성 · 중동식당 · 제민천 카페',
      'GONGJU',
      Icons.account_balance_rounded,
      AppTheme.coral,
    ),
    const _SavedCourse(
      '부여에서 만나는 백제',
      '백제문화단지 · 궁남지 · 로스터리',
      'BUYEO',
      Icons.park_rounded,
      AppTheme.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('찜한 코스'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: Text(
              '${_saved.length} saved',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    ),
    body: _saved.isEmpty
        ? const _SavedEmpty()
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              const Text(
                '나중에 다시 떠나고 싶은\n여행을 모아두었어요.',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '코스를 누르면 바로 여행을 이어갈 수 있어요.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ..._saved.map(
                (course) => _SavedCard(
                  course: course,
                  onRemove: () => setState(() => _saved.remove(course)),
                  onStart: () => context.go('/map'),
                ),
              ),
            ],
          ),
  );
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.course,
    required this.onRemove,
    required this.onStart,
  });
  final _SavedCourse course;
  final VoidCallback onRemove;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          height: 116,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                course.color.withValues(alpha: 0.9),
                course.color.withValues(alpha: 0.48),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(course.icon, color: Colors.white, size: 27),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.region,
                      style: TextStyle(
                        color: course.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.places,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onStart,
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.background,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SavedCourse {
  const _SavedCourse(
    this.title,
    this.places,
    this.region,
    this.icon,
    this.color,
  );
  final String title;
  final String places;
  final String region;
  final IconData icon;
  final Color color;
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppTheme.softMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bookmark_add_outlined,
            color: AppTheme.accent,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '아직 찜한 코스가 없어요',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          '마음에 드는 여행을 저장해보세요.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}
