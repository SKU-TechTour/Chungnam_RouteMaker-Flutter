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
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarded', true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F4),
    body: SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
                sliver: SliverList.list(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _finish,
                        child: const Text('건너뛰기'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _OpeningSection(),
                    const SizedBox(height: 68),
                    _RevealOnScroll(
                      progress: _revealProgress(330),
                      child: const _PreviewStory(
                        step: '01',
                        title: '날씨를 확인하고\n취향에 맞는 코스를 골라요',
                        description:
                            '지역별 시간대 날씨와 방문 목적, 관심사를 반영해\n나만의 여행 코스를 추천해요.',
                        asset: 'assets/images/onboarding/guide_home.png',
                        accent: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(850),
                      child: const _PreviewStory(
                        step: '02',
                        title: '나만의 큐레이션 루트를\n자유롭게 완성해요',
                        description:
                            '추천 장소를 추가하거나 삭제하고,\n마음에 드는 코스는 찜해둘 수 있어요.',
                        asset: 'assets/images/onboarding/guide_curation.png',
                        accent: AppTheme.coral,
                      ),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(1370),
                      child: const _PreviewStory(
                        step: '03',
                        title: '선택한 장소를 지도 위에서\n순서대로 안내해요',
                        description:
                            '경유지와 이동 순서를 한눈에 보고,\n지도에서 여행을 바로 시작할 수 있어요.',
                        asset: 'assets/images/onboarding/guide_route.png',
                        accent: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(1900),
                      child: const _PreviewStory(
                        step: '04',
                        title: '여행을 완주하고\n나만의 기록으로 남겨요',
                        description:
                            '코스의 모든 장소를 방문하면 완주 스탬프와\n공유 가능한 여행 기록 카드를 만들 수 있어요.',
                        asset: 'assets/images/onboarding/guide_stamp.png',
                        accent: AppTheme.coral,
                      ),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(2430),
                      child: const _PreviewStory(
                        step: '05',
                        title: '주변 장소를 살펴보고\n원하는 길로 바로 떠나요',
                        description:
                            '관광지 상세정보와 이동 편의 정보를 확인한 뒤,\n네이버지도 또는 카카오맵으로 길을 안내받아요.',
                        asset: 'assets/images/onboarding/guide_place.png',
                        accent: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(2970),
                      child: _FinalSection(onStart: _finish),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 58,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00F7F8F4), Color(0xFFF7F8F4)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  double _revealProgress(double threshold) =>
      ((_scrollOffset - threshold + 280) / 220).clamp(0.0, 1.0);
}

class _OpeningSection extends StatelessWidget {
  const _OpeningSection();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'WELCOME TO CHUNGNAM',
        style: TextStyle(
          color: AppTheme.primary,
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 20),
      Container(
        width: 118,
        height: 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Image.asset(
            'assets/images/brand/chungnam_route_maker_logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        '충남의 세 도시를 잇는\n여행을 시작해요',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.gowunDodum,
          fontSize: 34,
          height: 1.28,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '아래로 천천히 내려\n충남 루트메이커의 여행 방식을 확인해보세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 15,
          height: 1.55,
        ),
      ),
      const SizedBox(height: 26),
      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
    ],
  );
}

class _RevealOnScroll extends StatelessWidget {
  const _RevealOnScroll({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress,
    child: Transform.translate(
      offset: Offset(0, 38 * (1 - progress)),
      child: child,
    ),
  );
}

class _PreviewStory extends StatelessWidget {
  const _PreviewStory({
    required this.step,
    required this.title,
    required this.description,
    required this.asset,
    required this.accent,
  });

  final String step;
  final String title;
  final String description;
  final String asset;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.gowunDodum,
                    fontSize: 24,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                asset,
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _FinalSection extends StatelessWidget {
  const _FinalSection({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(34),
    ),
    child: Column(
      children: [
        const Icon(Icons.route_rounded, color: Colors.white, size: 34),
        const SizedBox(height: 16),
        const Text(
          '이제, 나만의 충남을\n만나러 갈까요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.gowunDodum,
            color: Colors.white,
            fontSize: 28,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text('충남 여행 시작하기'),
        ),
      ],
    ),
  );
}
