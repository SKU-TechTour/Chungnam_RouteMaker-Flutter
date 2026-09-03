import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../saved/viewmodels/saved_courses_provider.dart';
import '../models/receipt.dart';
import '../models/stamp.dart';

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
    final history = ref.watch(myHistoryViewModelProvider);
    final latestReceipt = history.receipts.isEmpty
        ? null
        : history.receipts.first;
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
                      const Expanded(
                        child: Text(
                          '나의 충남 여행 기록',
                          style: TextStyle(
                            fontFamily: AppTheme.gowunDodum,
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '로그아웃',
                        onPressed: () async {
                          await ref.read(authViewModelProvider).logout();
                          ref.read(homeSessionProvider.notifier).state = null;
                          ref.read(selectedRouteProvider.notifier).state = null;
                          ref.read(journeyProgressProvider.notifier).clear();
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
                        onPressed: latestReceipt == null
                            ? null
                            : () => _shareReceipt(context),
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
                    onTap: latestReceipt == null
                        ? null
                        : () => context.push('/history/receipt'),
                    child: RepaintBoundary(
                      key: _receiptCardKey,
                      child: latestReceipt == null
                          ? const _EmptyReceiptCard()
                          : _ReceiptCard(receipt: latestReceipt),
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
                  Row(children: _stampCards(history.stamps)),
                  const SizedBox(height: 30),
                  const _SectionTitle(
                    title: '지역 마스터 뱃지',
                    subtitle: '논산·공주·부여 코스를 모두 완주하면 획득해요.',
                  ),
                  const SizedBox(height: 14),
                  _MasterBadge(
                    unlocked: {'NONSAN', 'GONGJU', 'BUYEO'}.every(
                      (region) =>
                          history.stamps.any((stamp) => stamp.region == region),
                    ),
                    completedRegions: history.stamps
                        .where(
                          (stamp) => const {
                            'NONSAN',
                            'GONGJU',
                            'BUYEO',
                          }.contains(stamp.region),
                        )
                        .map((stamp) => stamp.region)
                        .toSet()
                        .length,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton(
                      onPressed: () => _confirmAccountDeletion(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('계정 및 여행 데이터 삭제'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: const Text(
          'Firebase 계정과 이 기기에 저장된 취향, 찜, 완주 기록이 모두 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await ref.read(authViewModelProvider).deleteAccount();
    if (!context.mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정 삭제를 완료하지 못했어요. 다시 로그인한 뒤 시도해주세요.')),
      );
      return;
    }
    ref.read(savedCoursesProvider.notifier).reset();
    ref.read(homeSessionProvider.notifier).state = null;
    ref.read(selectedRouteProvider.notifier).state = null;
    ref.read(journeyProgressProvider.notifier).clear();
    ref.invalidate(myHistoryViewModelProvider);
    if (context.mounted) context.go('/onboarding');
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
  const _ReceiptCard({required this.receipt});

  final Receipt receipt;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '충남 루트메이커',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${_regionLabel(receipt.region)} · ${_date(receipt.visitedAt)}',
                    style: const TextStyle(
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
        Text(
          receipt.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < receipt.places.length; index++)
          _ReceiptLine(
            number: '${index + 1}'.padLeft(2, '0'),
            title: receipt.places[index],
            category: '완료',
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: Color(0xFFE8DFCC)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL JOURNEY',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${receipt.amount} PLACES · 1 MEMORY',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

  static String _regionLabel(String value) => switch (value) {
    'GONGJU' => '공주',
    'BUYEO' => '부여',
    _ => '논산',
  };
}

class _EmptyReceiptCard extends StatelessWidget {
  const _EmptyReceiptCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8DFCC)),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 42,
          color: AppTheme.textSecondary,
        ),
        SizedBox(height: 14),
        Text('아직 완주한 여행이 없어요', style: TextStyle(fontWeight: FontWeight.w900)),
        SizedBox(height: 5),
        Text(
          '코스의 모든 장소에 도착하면 여행 영수증이 만들어져요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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

class _MasterBadge extends StatelessWidget {
  const _MasterBadge({required this.unlocked, required this.completedRegions});

  final bool unlocked;
  final int completedRegions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: unlocked
            ? const [AppTheme.primary, Color(0xFF286A62)]
            : const [Color(0xFF9A9E9D), Color(0xFF747877)],
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
              Text(
                unlocked ? '충남 3개 지역 마스터' : '충남 지역 마스터',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                unlocked
                    ? '논산·공주·부여 완주를 축하해요!'
                    : '논산·공주·부여 중 $completedRegions/3 지역 완주',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completedRegions.clamp(0, 3) / 3,
                  minHeight: 7,
                  color: unlocked ? AppTheme.coral : Colors.white70,
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

List<Widget> _stampCards(List<Stamp> stamps) {
  const regions = [
    ('NONSAN', '논산', AppTheme.coral, Icons.terrain_rounded),
    ('GONGJU', '공주', AppTheme.primary, Icons.account_balance_rounded),
    ('BUYEO', '부여', Color(0xFF8A5DB1), Icons.park_rounded),
  ];

  return regions.map((region) {
    Stamp? earned;
    for (final stamp in stamps) {
      if (stamp.region == region.$1) {
        earned = stamp;
        break;
      }
    }
    final date = earned == null
        ? '미완주'
        : '${earned.earnedAt.year}.${earned.earnedAt.month.toString().padLeft(2, '0')}.${earned.earnedAt.day.toString().padLeft(2, '0')}';
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: region.$1 == 'BUYEO' ? 0 : 8),
        child: _StampCard(
          region: region.$2,
          date: date,
          color: region.$3,
          icon: region.$4,
          locked: earned == null,
        ),
      ),
    );
  }).toList();
}
