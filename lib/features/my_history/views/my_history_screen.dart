import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/features/my_history/models/receipt.dart';
import 'package:flutterprojects/features/my_history/models/stamp.dart';

class MyHistoryScreen extends ConsumerStatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  ConsumerState<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends ConsumerState<MyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(myHistoryViewModelProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myHistoryViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('여행 기록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!))
              : _Content(receipts: state.receipts, stamps: state.stamps),
    );
  }
}

class _Content extends StatelessWidget {
  final List<Receipt> receipts;
  final List<Stamp> stamps;
  const _Content({required this.receipts, required this.stamps});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle(title: '완주 스탬프', count: stamps.length),
        const SizedBox(height: 12),
        _StampGrid(stamps: stamps),
        const SizedBox(height: 24),
        _SectionTitle(title: '여행 영수증', count: receipts.length),
        const SizedBox(height: 12),
        _ReceiptList(receipts: receipts),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _StampGrid extends StatelessWidget {
  final List<Stamp> stamps;
  const _StampGrid({required this.stamps});

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) return const _EmptyState(message: '아직 완주한 코스가 없어요');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
      ),
      itemCount: stamps.length,
      itemBuilder: (_, i) => _StampItem(stamp: stamps[i]),
    );
  }
}

class _StampItem extends StatelessWidget {
  final Stamp stamp;
  const _StampItem({required this.stamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.stars, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(height: 6),
          Text(stamp.label, style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            '${stamp.earnedAt.month}/${stamp.earnedAt.day}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  final List<Receipt> receipts;
  const _ReceiptList({required this.receipts});

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) return const _EmptyState(message: '아직 영수증이 없어요');
    return Column(
      children: receipts.map((r) => _ReceiptItem(receipt: r)).toList(),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  final Receipt receipt;
  const _ReceiptItem({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('${receipt.amount}원 · ${receipt.visitedAt.month}/${receipt.visitedAt.day}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
    );
  }
}
