import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';

const _regions = ['논산', '공주', '부여'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _timer;
  int _regionIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(
      () => ref.read(homeCurationViewModelProvider.notifier).loadCourses(),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted) return;
      final next = (_regionIndex + 1) % _regions.length;
      setState(() => _regionIndex = next);
      _tabController.animateTo(next);
    });
  }

  void _onTabTap(int i) {
    setState(() => _regionIndex = i);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeCurationViewModelProvider);
    final course = state.currentCourse;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: const Text(
                '루트메이커',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w400),
              indicatorColor: AppTheme.textPrimary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: _regions.map((r) => Tab(text: r)).toList(),
              onTap: _onTabTap,
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : course == null
                      ? const Center(child: Text('추천 코스가 없습니다'))
                      : _CourseContent(
                          course: course,
                          region: _regions[_regionIndex],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseContent extends StatelessWidget {
  final Course course;
  final String region;
  const _CourseContent({required this.course, required this.region});

  @override
  Widget build(BuildContext context) {
    final spots = course.spots;
    final spot1 = spots.isNotEmpty ? spots[0] : '';
    final spot2 = spots.length > 1 ? spots[1] : '';
    final spot3 = spots.length > 2 ? spots[2] : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              const Text(
                '맞춤형 3단 콤보',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('90% Match',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 이미지 카드
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // 큰 이미지 - 볼거리
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: const Color(0xFFB8C8B8),
                      child: const Icon(Icons.landscape,
                          size: 64, color: Colors.white54),
                    ),
                    if (course.weatherTag != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            course.weatherTag!,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Text(
                        '1. 볼거리 | $spot1',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 1))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // 작은 이미지 2개 - 먹거리 / 살거리
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 120,
                            color: const Color(0xFFC8B8A8),
                            child: const Center(
                              child: Icon(Icons.restaurant,
                                  size: 40, color: Colors.white54),
                            ),
                          ),
                          const Positioned(
                            bottom: 8,
                            left: 10,
                            child: Text(
                              '2. 먹거리',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54, blurRadius: 4)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 120,
                            color: const Color(0xFFA8B8C8),
                            child: const Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 40, color: Colors.white54),
                            ),
                          ),
                          const Positioned(
                            bottom: 8,
                            left: 10,
                            child: Text(
                              '3. 살거리',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54, blurRadius: 4)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 코스 제목
          Text(
            course.title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '$spot1 · $spot2 · $spot3 코스를 탐험해보세요',
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 20),

          // CTA 버튼
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '이 코스 시작하기',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
