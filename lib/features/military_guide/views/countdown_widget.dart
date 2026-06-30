import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';

/// [SB 화면 2] 복귀 카운트다운 위젯.
///
/// MethodChannel은 ViewModel → Repository → LiveWidgetChannel 경로로만 접근합니다.
class CountdownWidget extends ConsumerStatefulWidget {
  const CountdownWidget({super.key});

  @override
  ConsumerState<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends ConsumerState<CountdownWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(militaryGuideViewModelProvider.notifier).startCountdown(),
    );
  }

  @override
  void dispose() {
    ref.read(militaryGuideViewModelProvider.notifier).stopCountdown();
    super.dispose();
  }

  String _format(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(militaryGuideViewModelProvider);

    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(state.errorMessage!),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('복귀까지 남은 시간'),
            const SizedBox(height: 8),
            Text(
              _format(state.secondsLeft),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}
