import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _items = [
    _OnboardingItem(
      eyebrow: 'CURATED FOR YOU',
      title: '하루가 가벼워지는\n세 곳의 조합',
      description: '보고, 먹고, 쉬는 곳까지.\n당신의 취향으로 여행을 엮어드려요.',
      icon: Icons.auto_awesome_rounded,
      color: AppTheme.coral,
      background: AppTheme.softCoral,
    ),
    _OnboardingItem(
      eyebrow: 'SMART PLAN B',
      title: '날씨가 바뀌어도\n여행은 멈추지 않게',
      description: '비 오는 날에도 좋은 실내 코스를\n한 번의 탭으로 제안해요.',
      icon: Icons.cloudy_snowing,
      color: Color(0xFF5B7CFA),
      background: Color(0xFFE8ECFF),
    ),
    _OnboardingItem(
      eyebrow: 'TRAVEL PASSPORT',
      title: '걸어온 여행을\n나만의 기록으로',
      description: '완주 스탬프와 영수증 카드로\n오늘의 여정을 간직하세요.',
      icon: Icons.verified_user_rounded,
      color: AppTheme.accent,
      background: AppTheme.softMint,
    ),
  ];

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarded', true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_page];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('건너뛰기'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: _items.length,
                  itemBuilder: (_, index) =>
                      _OnboardingPage(item: _items[index]),
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: index == _page ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: index == _page ? item.color : AppTheme.divider,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1} / ${_items.length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _page == _items.length - 1
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      ),
                style: FilledButton.styleFrom(backgroundColor: item.color),
                child: Text(_page == _items.length - 1 ? '여행 시작하기' : '다음 이야기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final illustrationHeight = constraints.maxHeight < 560 ? 210.0 : 310.0;
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: illustrationHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.background,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: illustrationHeight * 0.62,
                    height: illustrationHeight * 0.62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    item.icon,
                    color: item.color,
                    size: illustrationHeight * 0.28,
                  ),
                  Positioned(top: 28, left: 28, child: _Dot(color: item.color)),
                  Positioned(
                    bottom: 30,
                    right: 34,
                    child: _Dot(color: item.color, small: true),
                  ),
                ],
              ),
            ),
            SizedBox(height: constraints.maxHeight < 560 ? 24 : 46),
            Text(
              item.eyebrow,
              style: TextStyle(
                color: item.color,
                letterSpacing: 1.4,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 30,
                height: 1.22,
                letterSpacing: -1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.small = false});
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
    width: small ? 12 : 18,
    height: small ? 12 : 18,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.75),
      shape: BoxShape.circle,
    ),
  );
}
