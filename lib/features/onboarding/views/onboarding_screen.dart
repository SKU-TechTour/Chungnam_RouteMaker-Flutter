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
                    const SizedBox(height: 72),
                    _RevealOnScroll(
                      progress: _revealProgress(150),
                      child: const _ImageStorySection(
                        eyebrow: 'WELCOME TO CHUNGNAM',
                        title: '충남의 세 도시를 잇는\n여행을 시작해요',
                        description: '공주·부여·논산의 문화와 풍경을\n당신의 취향에 맞게 이어드릴게요.',
                        asset:
                            'assets/images/brand/chungnam_route_maker_logo.png',
                        accent: Color(0xFFF28A42),
                      ),
                    ),
                    const SizedBox(height: 84),
                    _RevealOnScroll(
                      progress: _revealProgress(620),
                      child: const _ImageStorySection(
                        eyebrow: 'ROUTE FOR YOUR MOMENT',
                        title: '입영의 하루부터\n가벼운 주말 여행까지',
                        description: '입영객과 동행 지인, 일반 여행객까지\n상황에 맞는 동선을 골라드려요.',
                        asset: 'assets/images/onboarding/travelers.png',
                        accent: AppTheme.primary,
                        imageFirst: false,
                      ),
                    ),
                    const SizedBox(height: 84),
                    _RevealOnScroll(
                      progress: _revealProgress(1080),
                      child: const _ImageStorySection(
                        eyebrow: 'LIVE CURATION',
                        title: '날씨와 이동시간을 읽고\n지금의 코스를 만들어요',
                        description:
                            'TourAPI 관광정보·기상청 예보·카카오 이동정보를\n실시간으로 조합해 다섯 가지 루트를 제안해요.',
                        asset: 'assets/images/onboarding/road_trip.png',
                        accent: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 84),
                    _RevealOnScroll(
                      progress: _revealProgress(1520),
                      child: const _AppPreviewSection(),
                    ),
                    const SizedBox(height: 70),
                    _RevealOnScroll(
                      progress: _revealProgress(2050),
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
        '충남 루트메이커',
        style: TextStyle(
          color: AppTheme.primary,
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '당신의 하루가\n하나의 여행이 되도록',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.gowunDodum,
          fontSize: 34,
          height: 1.28,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        '아래로 천천히 내려\n충남에서 만날 여정을 확인해보세요.',
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

class _ImageStorySection extends StatelessWidget {
  const _ImageStorySection({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.asset,
    required this.accent,
    this.imageFirst = true,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String asset;
  final Color accent;
  final bool imageFirst;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      height: 310,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: accent,
            letterSpacing: 1.25,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.gowunDodum,
            fontSize: 29,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageFirst
          ? [image, const SizedBox(height: 26), copy]
          : [copy, const SizedBox(height: 26), image],
    );
  }
}

class _AppPreviewSection extends StatelessWidget {
  const _AppPreviewSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'YOUR ROUTE, IN ONE PLACE',
        style: TextStyle(
          color: AppTheme.coral,
          letterSpacing: 1.25,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        '고르고, 출발하고,\n기억으로 남겨요',
        style: TextStyle(
          fontFamily: AppTheme.gowunDodum,
          fontSize: 29,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 26),
      const _PreviewStory(
        step: '01',
        title: '날씨를 확인하고\n취향에 맞는 코스를 골라요',
        description: '지역별 시간대 날씨와 선택한 관심사를 반영한\n추천 코스를 한 화면에서 확인할 수 있어요.',
        asset: 'assets/images/onboarding/home_preview.jpg',
        accent: AppTheme.primary,
      ),
      const SizedBox(height: 48),
      const _PreviewStory(
        step: '02',
        title: '마음에 드는 코스는\n찜해두고 바로 출발해요',
        description: '저장한 경유지를 그대로 유지해\n원하는 순간 지도에서 코스를 시작할 수 있어요.',
        asset: 'assets/images/onboarding/saved_preview.jpg',
        accent: AppTheme.coral,
      ),
    ],
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
          widthFactor: 0.56,
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
              child: AspectRatio(
                aspectRatio: 1080 / 2340,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  color: const Color(0xFFF7F8F4),
                  colorBlendMode: BlendMode.dstOver,
                ),
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
