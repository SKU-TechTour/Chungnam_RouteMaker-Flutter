import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/widgets/error_widget.dart';
import 'package:flutterprojects/core/widgets/loading_widget.dart';
import 'package:flutterprojects/features/home_curation/views/widgets/combo_card.dart';

/// [SB 화면 1] 홈 큐레이션 및 날씨 셔플 화면.
///
/// UI만 담당 — 상태는 [HomeCurationViewModel]을 구독합니다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(homeCurationViewModelProvider.notifier).loadCourses(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeCurationViewModelProvider);
    final notifier = ref.read(homeCurationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('홈 큐레이션')),
      body: switch ((state.isLoading, state.errorMessage, state.currentCourse)) {
        (true, _, _) => const LoadingWidget(),
        (_, String msg, _) => AppErrorWidget(
            message: msg,
            onRetry: notifier.loadCourses,
          ),
        (_, _, null) => const Center(child: Text('추천 코스가 없습니다')),
        (_, _, final course) => Column(
            children: [
              Expanded(
                child: ComboCard(
                  course: course!,
                  onSwipe: notifier.onSwipe,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: notifier.shuffleToNext,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Plan B 셔플'),
                ),
              ),
            ],
          ),
      },
    );
  }
}
