import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../models/stamp.dart';

class StampSharePreviewScreen extends ConsumerStatefulWidget {
  const StampSharePreviewScreen({super.key});

  @override
  ConsumerState<StampSharePreviewScreen> createState() =>
      _StampSharePreviewScreenState();
}

class _StampSharePreviewScreenState
    extends ConsumerState<StampSharePreviewScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(myHistoryViewModelProvider.notifier).loadHistory(),
    );
  }

  Future<void> _share(BuildContext context) async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || !context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          subject: '충남 루트메이커 완주 스탬프',
          text: '#충남루트메이커 #충남여행 #완주스탬프',
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'chungnam-stamp-card.png',
            ),
          ],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(myHistoryViewModelProvider);
    final previewMode = history.stamps.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('스탬프 공유 카드')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            previewMode ? '완주 전에는 예시 디자인으로 보여드려요.' : '현재 획득한 스탬프가 카드에 반영됐어요.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            key: _cardKey,
            child: _StampShareCard(
              stamps: history.stamps,
              previewMode: previewMode,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _sharing ? null : () => _share(context),
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(_sharing ? '이미지 만드는 중' : '이 카드 이미지 공유하기'),
          ),
        ],
      ),
    );
  }
}

class _StampShareCard extends StatelessWidget {
  const _StampShareCard({required this.stamps, required this.previewMode});

  final List<Stamp> stamps;
  final bool previewMode;

  @override
  Widget build(BuildContext context) {
    const regions = [
      ('NONSAN', '논산', 'NONSAN', AppTheme.coral, Icons.terrain_rounded),
      (
        'GONGJU',
        '공주',
        'GONGJU',
        AppTheme.primary,
        Icons.account_balance_rounded,
      ),
      ('BUYEO', '부여', 'BUYEO', Color(0xFF8A5DB1), Icons.park_rounded),
    ];
    final completed = previewMode
        ? 3
        : regions.where((region) => _earned(region.$1)).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF4), Color(0xFFF2F8F4)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4DDCF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/brand/chungnam_route_maker_logo.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHUNGNAM ROUTE MAKER',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '나의 충남 여행 도장',
                      style: TextStyle(
                        fontFamily: AppTheme.gowunDodum,
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
              ),
              if (previewMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '예시',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Divider(color: Color(0xFFE4DDCF)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: regions.map((region) {
              final earned = previewMode || _earned(region.$1);
              return _ShareStamp(
                region: region.$2,
                code: region.$3,
                color: region.$4,
                icon: region.$5,
                earned: earned,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: completed == 3
                  ? AppTheme.primary
                  : const Color(0xFFE3E6E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  completed == 3
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: completed == 3 ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    completed == 3
                        ? '충남 3개 지역 마스터 달성'
                        : '지역 마스터까지 $completed/3',
                    style: TextStyle(
                      color: completed == 3
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '논산 · 공주 · 부여에서 완성한 우리의 여행',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  bool _earned(String region) => stamps.any((stamp) => stamp.region == region);
}

class _ShareStamp extends StatelessWidget {
  const _ShareStamp({
    required this.region,
    required this.code,
    required this.color,
    required this.icon,
    required this.earned,
  });

  final String region;
  final String code;
  final Color color;
  final IconData icon;
  final bool earned;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: earned ? 1 : 0.35,
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: earned ? color.withValues(alpha: 0.12) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            earned ? icon : Icons.lock_outline_rounded,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          region,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        Text(
          earned ? code : 'LOCKED',
          style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}
