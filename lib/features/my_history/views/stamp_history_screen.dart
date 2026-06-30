import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';

/// [SB 화면 4] 로컬 스탬프/뱃지 이력 화면.
class StampHistoryScreen extends ConsumerStatefulWidget {
  const StampHistoryScreen({super.key});

  @override
  ConsumerState<StampHistoryScreen> createState() => _StampHistoryScreenState();
}

class _StampHistoryScreenState extends ConsumerState<StampHistoryScreen> {
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
      appBar: AppBar(
        title: Text('스탬프 ${state.stampCount}개'),
      ),
      body: state.stamps.isEmpty
          ? const Center(child: Text('아직 획득한 스탬프가 없습니다'))
          : ListView.builder(
              itemCount: state.stamps.length,
              itemBuilder: (context, index) {
                final stamp = state.stamps[index];
                return ListTile(
                  leading: const Icon(Icons.military_tech),
                  title: Text(stamp.label),
                  subtitle: Text(stamp.earnedAt.toString()),
                );
              },
            ),
    );
  }
}
