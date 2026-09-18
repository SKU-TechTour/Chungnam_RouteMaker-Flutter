import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/providers.dart';
import '../../../core/widgets/external_map_buttons.dart';
import '../models/saved_course.dart';
import '../models/saved_place.dart';
import '../viewmodels/saved_courses_provider.dart';
import '../viewmodels/saved_places_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(savedCoursesProvider);
    final places = ref.watch(savedPlacesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('찜'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  '${courses.length + places.length}개',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '찜한 코스'),
              Tab(text: '찜한 장소'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            courses.isEmpty
                ? const _SavedEmpty(
                    title: '아직 찜한 코스가 없어요',
                    description: '홈에서 마음에 드는 여행 코스를 저장해보세요.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const Text(
                        '다시 떠나고 싶은\n여행을 모아두었어요.',
                        style: TextStyle(
                          fontSize: 26,
                          height: 1.24,
                          letterSpacing: -0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '홈에서 저장한 조합이 이곳에 바로 반영돼요.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ...courses.asMap().entries.map(
                        (entry) => _SavedCard(
                          course: entry.value,
                          index: entry.key,
                          onRemove: () => ref
                              .read(savedCoursesProvider.notifier)
                              .remove(entry.value.id),
                          onStart: () {
                            final route = entry.value.toSelectedRoute();
                            ref.read(selectedRouteProvider.notifier).state =
                                route;
                            context.go('/map');
                          },
                        ),
                      ),
                    ],
                  ),
            places.isEmpty
                ? const _SavedEmpty(
                    title: '아직 찜한 장소가 없어요',
                    description: '주변 코스 지도에서 장소를 눌러 저장해보세요.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: places.length,
                    itemBuilder: (context, index) => _SavedPlaceCard(
                      place: places[index],
                      onRemove: () => ref
                          .read(savedPlacesProvider.notifier)
                          .remove(places[index]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.course,
    required this.index,
    required this.onRemove,
    required this.onStart,
  });
  final SavedCourse course;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.region,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                tooltip: '찜 해제',
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          ...course.places.asMap().entries.map(
            (place) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${place.key + 1}',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      place.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('이 코스로 출발하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

const _colors = [AppTheme.coral, AppTheme.accent, Color(0xFF6B68D9)];

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({required this.place, required this.onRemove});

  final SavedPlace place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.softMint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${place.regionLabel} · ${place.categoryLabel}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: '장소 찜 해제',
              onPressed: onRemove,
              icon: const Icon(Icons.bookmark_rounded),
              color: AppTheme.primary,
            ),
          ],
        ),
        Text(
          place.name,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        if (place.address?.isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(
            place.address!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        ExternalMapButtons(
          name: place.name,
          latitude: place.latitude,
          longitude: place.longitude,
        ),
      ],
    ),
  );
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppTheme.softMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bookmark_add_outlined,
            color: AppTheme.accent,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}
