import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class MyHistoryScreen extends ConsumerStatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  ConsumerState<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends ConsumerState<MyHistoryScreen> {
  final _receiptCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(myHistoryViewModelProvider.notifier).loadHistory(),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final boundary =
        _receiptCardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null || !mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        subject: '충남 루트메이커 여행 기록',
        text: '#충남루트메이커 #논산여행 #로컬여행',
        files: [
          XFile.fromData(
            byteData.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'chungnam-route-card.png',
          ),
        ],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final history = ref.watch(myHistoryViewModelProvider);
    final visitedPlaces = history.receipts.fold<int>(
      0,
      (sum, receipt) => sum + receipt.amount,
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppTheme.softMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user?.name ?? '여행자'}님, 반가워요',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              '나의 충남 여행 기록',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '로그아웃',
                        onPressed: () async {
                          await ref.read(authViewModelProvider).logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${history.receipts.length}',
                          label: '완주 코스',
                          icon: Icons.route_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$visitedPlaces',
                          label: '방문 장소',
                          icon: Icons.place_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${history.stamps.length}',
                          label: '획득 뱃지',
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Maker Receipt',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '오늘의 여행을 한 장에 담았어요.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _shareReceipt(context),
                        icon: const Icon(Icons.ios_share_rounded, size: 17),
                        label: const Text('기록 공유'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.push('/history/receipt'),
                    child: RepaintBoundary(
                      key: _receiptCardKey,
                      child: const _ReceiptCard(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(
                        child: _SectionTitle(
                          title: '완주 스탬프',
                          subtitle: '도장을 모아 충남 여행 지도를 완성해보세요.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/history/stamps'),
                        child: const Text('전체 보기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: _StampCard(
                          region: '논산',
                          date: '08.24',
                          color: AppTheme.coral,
                          icon: Icons.camera_alt_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StampCard(
                          region: '공주',
                          date: '08.12',
                          color: AppTheme.accent,
                          icon: Icons.account_balance_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StampCard(
                          region: '부여',
                          date: '다음 여행',
                          color: Color(0xFF6B68D9),
                          icon: Icons.lock_outline_rounded,
                          locked: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(
                    title: '나의 로컬 혜택',
                    subtitle: '여행할수록 커지는 지역별 혜택이에요.',
                  ),
                  const SizedBox(height: 14),
                  const _BenefitCard(
                    icon: Icons.local_cafe_rounded,
                    color: AppTheme.coral,
                    title: '논산 로컬 카페 10% 할인',
                    description: '논산 콤보 완주자 전용 · 9월 30일까지',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitCard(
                    icon: Icons.confirmation_number_rounded,
                    color: AppTheme.accent,
                    title: '공주 박물관 굿즈 쿠폰',
                    description: '공주 마스터 레벨 1 달성 혜택',
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(
                    title: '지역 마스터 뱃지',
                    subtitle: '지역을 더 깊이 여행하면 뱃지가 성장해요.',
                  ),
                  const SizedBox(height: 14),
                  const _MasterBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, size: 19, color: AppTheme.accent),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8DFCC)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/brand/chungnam_route_maker_logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '충남 루트메이커',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'NONSAN · 2026.08.24',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppTheme.coral),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFE8DFCC)),
        ),
        const Text(
          '논산에서 만든 우리의 하루',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 18),
        const _ReceiptLine(number: '01', title: '선샤인 스튜디오', category: '볼거리'),
        const _ReceiptLine(number: '02', title: '연무대 골목 고기집', category: '먹거리'),
        const _ReceiptLine(number: '03', title: '탑정호 베이커리카페', category: '쉴거리'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: Color(0xFFE8DFCC)),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL JOURNEY',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Text(
              '3 PLACES · 1 MEMORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({
    required this.number,
    required this.title,
    required this.category,
  });
  final String number;
  final String title;
  final String category;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppTheme.coral,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          category,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    ],
  );
}

class _StampCard extends StatelessWidget {
  const _StampCard({
    required this.region,
    required this.date,
    required this.color,
    required this.icon,
    this.locked = false,
  });
  final String region;
  final String date;
  final Color color;
  final IconData icon;
  final bool locked;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: locked ? 0.5 : 1,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            region,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title 혜택은 데모 종료 후 쿠폰함에서 사용할 수 있어요.')),
    ),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _MasterBadge extends StatelessWidget {
  const _MasterBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primary, Color(0xFF286A62)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/brand/chungnam_route_maker_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '논산 로컬 마스터',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '다음 레벨까지 장소 2곳',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 7,
                  color: AppTheme.coral,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
