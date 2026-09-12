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
      eyebrow: 'CHUNGNAM, MADE FOR YOU',
      title: '입영의 하루부터\n주말 여행까지',
      description: '공주·부여·논산의 숨은 순간을\n당신의 상황과 취향에 맞춰 연결해요.',
      icon: Icons.auto_awesome_rounded,
      color: AppTheme.coral,
      background: AppTheme.softCoral,
      callouts: ['논산 입영', '공주 역사', '부여 힐링'],
    ),
    _OnboardingItem(
      eyebrow: 'LIVE CURATION',
      title: '날씨와 취향을 읽는\n나만의 실시간 코스',
      description: 'TourAPI 관광정보와 기상청 예보를 조합해\n지금 어울리는 여정을 제안해요.',
      icon: Icons.cloudy_snowing,
      color: Color(0xFF5B7CFA),
      background: Color(0xFFE8ECFF),
      callouts: ['실시간 날씨', '취향별 추천', 'Plan B'],
    ),
    _OnboardingItem(
      eyebrow: 'PRIVATE TRAVEL PASSPORT',
      title: '500m의 도착이\n여행 기록이 되는 순간',
      description: 'GPS는 기기 안에서만 계산하고\n완주 스탬프와 영수증 카드로 남겨요.',
      icon: Icons.verified_user_rounded,
      color: AppTheme.accent,
      background: AppTheme.softMint,
      callouts: ['기기 내 GPS', '완주 스탬프', '공유 카드'],
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
    required this.callouts,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
  final List<String> callouts;
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.background, Colors.white],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: item.color.withValues(alpha: 0.12)),
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
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: item.callouts
                          .map(
                            (label) => Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.color.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: item.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
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
                fontFamily: AppTheme.gowunDodum,
                fontSize: 30,
                height: 1.22,
                letterSpacing: -1.1,
                fontWeight: FontWeight.w400,
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
