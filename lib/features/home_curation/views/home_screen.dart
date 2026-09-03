import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/route_maker_logo.dart';
import '../../saved/models/saved_course.dart';
import '../../saved/viewmodels/saved_courses_provider.dart';
import '../models/course.dart';
import '../models/home_session.dart';
import '../models/selected_route.dart';
import '../../travel_preferences/models/travel_preferences.dart';
import '../../travel_preferences/repositories/travel_preferences_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _regionIndex = 0;
  var _party = TravelParty.traveler;
  var _duration = TripDuration.dayTrip;
  var _routeTemplate = RouteTemplate.travelerFlexible;
  Set<TravelConcept> _concepts = TravelConcept.values.toSet();
  List<CourseSpot> _editableSpots = [];
  var _selectedVariant = 0;
  RouteMetrics? _previewMetrics;
  bool _routeUpdating = false;

  final _preferencesRepository = TravelPreferencesRepository();

  _RegionCombo get _combo => _combos[_regionIndex];

  @override
  void initState() {
    super.initState();
    final session = ref.read(homeSessionProvider);
    if (session != null) {
      _regionIndex = session.regionIndex;
      _party = session.preferences.party;
      _duration = session.preferences.duration;
      _routeTemplate = session.preferences.routeTemplate;
      _concepts = session.preferences.concepts;
      _editableSpots = List.of(session.editableSpots);
      _selectedVariant = session.selectedVariant;
      _previewMetrics = session.previewMetrics;
    }
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesRepository.load();
    if (!mounted) return;
    if (preferences != null) {
      setState(() {
        _party = preferences.party;
        _duration = preferences.duration;
        _routeTemplate = preferences.routeTemplate;
        _concepts = preferences.concepts;
      });
    }
    final existing = ref.read(homeSessionProvider);
    if (existing != null &&
        (preferences == null ||
            existing.preferenceSignature ==
                travelPreferenceSignature(preferences))) {
      return;
    }
    await _loadRegion();
  }

  TravelPreferences get _preferences => TravelPreferences(
    party: _party,
    concepts: _concepts,
    duration: _duration,
    routeTemplate: _routeTemplate,
  );

  void _persistSession() {
    final preferences = _preferences;
    ref.read(homeSessionProvider.notifier).state = HomeSession(
      regionIndex: _regionIndex,
      preferences: preferences,
      preferenceSignature: travelPreferenceSignature(preferences),
      editableSpots: List.unmodifiable(_editableSpots),
      selectedVariant: _selectedVariant,
      previewMetrics: _previewMetrics,
    );
  }

  Future<void> _loadRegion() async {
    final nonsanTemplate = _combo.code == 'NONSAN'
        ? _routeTemplate
        : RouteTemplate.travelerFlexible;
    await ref
        .read(homeCurationViewModelProvider.notifier)
        .loadCourses(
          region: _combo.code,
          military: _combo.code == 'NONSAN' && _party != TravelParty.traveler,
          journeyType: _party.name,
          routeTemplate: nonsanTemplate.apiCode,
          concepts: _concepts.map((concept) => concept.name).toSet(),
        );
    if (!mounted) return;
    final courses = ref.read(homeCurationViewModelProvider).courses;
    if (courses.isNotEmpty) _applyVariant(0, courses);
  }

  void _selectRegion(int index) {
    setState(() {
      _regionIndex = index;
      _selectedVariant = 0;
      _editableSpots = [];
      _previewMetrics = null;
    });
    _persistSession();
    _loadRegion();
  }

  void _applyVariant(int index, List<Course> courses) {
    final selected = courses[index.clamp(0, courses.length - 1)];
    ref.read(homeCurationViewModelProvider.notifier).onSwipe(index);
    setState(() {
      _selectedVariant = index;
      _editableSpots = List.of(selected.spots);
      _previewMetrics = RouteMetrics(
        distanceMeters: selected.totalDistanceMeters,
        durationSeconds: selected.totalDurationSeconds,
      );
    });
    _persistSession();
  }

  Future<void> _refreshRoute() async {
    final spots = _editableSpots;
    if (spots.length < 2 || spots.any((spot) => spot.latitude == 0)) return;
    setState(() => _routeUpdating = true);
    try {
      final metrics = await ref
          .read(courseRepositoryProvider)
          .previewRoute(spots);
      if (mounted) {
        setState(() => _previewMetrics = metrics);
        _persistSession();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('변경한 장소의 이동시간을 계산하지 못했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _routeUpdating = false);
    }
  }

  void _removeSpot(int index) {
    if (_editableSpots[index].id == '-1' || _editableSpots.length <= 2) return;
    setState(() => _editableSpots.removeAt(index));
    _persistSession();
    _refreshRoute();
  }

  void _replaceSpot(int index, CourseSpot replacement) {
    setState(() => _editableSpots[index] = replacement);
    _persistSession();
    _refreshRoute();
  }

  void _showAddSpot(List<CourseSpot> candidates) {
    final existing = _editableSpots.map((spot) => spot.id).toSet();
    final available = candidates
        .where((spot) => !existing.contains(spot.id))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '경유지 추가',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (available.isEmpty)
              const ListTile(title: Text('추가할 수 있는 실시간 추천 장소가 없어요.')),
            ...available.map(
              (spot) => ListTile(
                leading: Icon(_spotIcon(spot.category)),
                title: Text(spot.name),
                subtitle: Text(_categoryLabel(spot.category)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _editableSpots.add(spot));
                  _persistSession();
                  _refreshRoute();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpotDetails({
    required String name,
    required String category,
    CourseSpot? spot,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpotDetailSheet(
        name: name,
        category: category,
        spot: spot,
        details: spot != null && spot.source == 'TOUR_API_REALTIME'
            ? ref.read(courseRepositoryProvider).fetchSpotDetails(spot.id)
            : Future.value(null),
      ),
    );
  }

  SavedCourse _selectedCourse(Course? liveCourse, List<CourseSpot> spots) =>
      SavedCourse(
        id: '${_combo.code}-${_routeTemplate.apiCode}-$_selectedVariant',
        region: _combo.name,
        regionCode: _combo.code,
        title: liveCourse?.title ?? '${_combo.name} 취향 맞춤 코스',
        spots: List.unmodifiable(spots),
        totalDistanceMeters:
            _previewMetrics?.distanceMeters ??
            liveCourse?.totalDistanceMeters ??
            0,
        totalDurationSeconds:
            _previewMetrics?.durationSeconds ??
            liveCourse?.totalDurationSeconds ??
            0,
      );

  @override
  Widget build(BuildContext context) {
    final curationState = ref.watch(homeCurationViewModelProvider);
    final loading = curationState.isLoading;
    final liveCourse = curationState.currentCourse;
    final candidateSpots = _uniqueSpots(
      curationState.courses.expand((course) => course.spots),
    );
    final saved = ref.watch(savedCoursesProvider);
    final selectedSpots = _editableSpots;
    final selectedCourse = _selectedCourse(liveCourse, selectedSpots);
    final isSaved = saved.any((course) => course.hasSameRoute(selectedCourse));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const RouteMakerLogo(compact: true),
                      const Spacer(),
                      IconButton(
                        tooltip: '알림',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('새로운 여행 소식이 도착하면 알려드릴게요.'),
                              ),
                            ),
                        icon: const Icon(Icons.notifications_none_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '오늘은 충남 어디로\n떠나볼까요?',
                    style: TextStyle(
                      fontFamily: AppTheme.gowunDodum,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HourlyWeatherCard(
                    region: _combo.name,
                    course: liveCourse,
                    loading: loading,
                  ),
                  const SizedBox(height: 26),
                  _RegionSelector(
                    selected: _regionIndex,
                    onSelected: _selectRegion,
                  ),
                  if (_combo.code == 'NONSAN') ...[
                    const SizedBox(height: 16),
                    _NonsanEntryCard(
                      party: _party,
                      duration: _duration,
                      routeTemplate: _routeTemplate,
                      course: liveCourse,
                      onEdit: () => context.push('/preferences'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PreferenceSummary(
                    concepts: _concepts,
                    onEdit: () => context.push('/preferences'),
                  ),
                  const SizedBox(height: 26),
                  if (curationState.errorMessage != null) ...[
                    _ApiErrorBanner(
                      message: curationState.errorMessage!,
                      onRetry: _loadRegion,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '나만의 큐레이션 루트',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_editableSpots.length}개 경유지 · 추가하거나 삭제할 수 있어요.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softMint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '취향 일치 92%',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (liveCourse != null)
                    _LiveCourseSource(course: liveCourse)
                  else if (ApiConstants.useMockData)
                    _ConceptCatalog(combo: _combo, concepts: _concepts),
                  if (liveCourse == null && !ApiConstants.useMockData)
                    const _RealtimeWaitingCard(),
                  const SizedBox(height: 18),
                  if (curationState.courses.length >= 5) ...[
                    _RouteVariantSelector(
                      count: 5,
                      selected: _selectedVariant,
                      onSelected: (index) =>
                          _applyVariant(index, curationState.courses),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ..._editableSpots.asMap().entries.expand((entry) {
                    final index = entry.key;
                    final spot = entry.value;
                    final alternatives = spot.id == '-1'
                        ? [spot]
                        : candidateSpots
                              .where(
                                (candidate) =>
                                    candidate.category == spot.category ||
                                    candidate.id == spot.id,
                              )
                              .toList();
                    final selectedIndex = alternatives.indexWhere(
                      (candidate) => candidate.id == spot.id,
                    );
                    return [
                      _ComboStep(
                        number: index + 1,
                        label:
                            spot.scheduledTime ?? _categoryLabel(spot.category),
                        icon: _spotIcon(spot.category),
                        color: _spotColor(spot.category),
                        options: alternatives.isEmpty
                            ? [spot.name]
                            : alternatives.map((item) => item.name).toList(),
                        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                        onChanged: (value) =>
                            _replaceSpot(index, alternatives[value]),
                        onInfo: () => _showSpotDetails(
                          name: spot.name,
                          category: _categoryLabel(spot.category),
                          spot: spot,
                        ),
                        onDelete: spot.id == '-1' || _editableSpots.length <= 2
                            ? null
                            : () => _removeSpot(index),
                      ),
                      if (index < _editableSpots.length - 1)
                        const _RouteConnector(),
                    ];
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        candidateSpots.isEmpty || _editableSpots.length >= 12
                        ? null
                        : () => _showAddSpot(candidateSpots),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('경유지 추가'),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              '예상 여행 시간',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _routeUpdating
                                  ? '재계산 중'
                                  : _formatDuration(
                                      _previewMetrics?.durationSeconds ??
                                          liveCourse?.totalDurationSeconds ??
                                          0,
                                      fallback: _combo.duration,
                                    ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    liveCourse != null ||
                                        ApiConstants.useMockData
                                    ? () {
                                        ref
                                            .read(savedCoursesProvider.notifier)
                                            .toggle(selectedCourse);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isSaved
                                                  ? '찜에서 삭제했어요.'
                                                  : '찜한 코스에 저장했어요.',
                                            ),
                                          ),
                                        );
                                      }
                                    : _loadRegion,
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                ),
                                label: Text(isSaved ? '저장됨' : '찜하기'),
                                style: OutlinedButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed:
                                    liveCourse != null ||
                                        ApiConstants.useMockData
                                    ? () {
                                        ref
                                            .read(
                                              selectedRouteProvider.notifier,
                                            )
                                            .state = SelectedRoute(
                                          title:
                                              liveCourse?.title ??
                                              '${_combo.name} 취향 맞춤 코스',
                                          region: _combo.code,
                                          spots: selectedSpots,
                                          totalDistanceMeters:
                                              _previewMetrics?.distanceMeters ??
                                              liveCourse?.totalDistanceMeters ??
                                              0,
                                          totalDurationSeconds:
                                              _previewMetrics
                                                  ?.durationSeconds ??
                                              liveCourse
                                                  ?.totalDurationSeconds ??
                                              0,
                                        );
                                        context.go('/map');
                                      }
                                    : _loadRegion,
                                icon: const Icon(Icons.navigation_rounded),
                                label: const Text('이 루트 시작하기'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<CourseSpot> _uniqueSpots(Iterable<CourseSpot> spots) {
  final byId = <String, CourseSpot>{};
  for (final spot in spots) {
    byId.putIfAbsent(spot.id, () => spot);
  }
  return byId.values.toList();
}

String _formatDuration(int seconds, {required String fallback}) {
  if (seconds <= 0) return fallback;
  final minutes = (seconds / 60).round();
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return hours > 0 ? '약 $hours시간 $remainder분' : '약 $remainder분';
}

String _categoryLabel(String category) => switch (category) {
  'RESTAURANT' => '맛집',
  'CAFE' => '카페',
  'ACCOMMODATION' => '숙소',
  _ => '유적지·관광지',
};

IconData _spotIcon(String category) => switch (category) {
  'RESTAURANT' => Icons.restaurant_rounded,
  'CAFE' => Icons.local_cafe_rounded,
  'ACCOMMODATION' => Icons.hotel_rounded,
  _ => Icons.account_balance_rounded,
};

Color _spotColor(String category) => switch (category) {
  'RESTAURANT' => AppTheme.coral,
  'CAFE' => const Color(0xFF6B68D9),
  'ACCOMMODATION' => const Color(0xFF2E6EA6),
  _ => AppTheme.accent,
};

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: List.generate(_combos.length, (index) {
        final active = selected == index;
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _combos[index].name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

class _LiveCourseSource extends StatelessWidget {
  const _LiveCourseSource({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.softMint,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.cloud_done_outlined, size: 18, color: AppTheme.primary),
            SizedBox(width: 7),
            Text(
              '실시간 공공데이터 추천',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${course.title}\n관광지는 TourAPI, 날씨는 기상청, 이동시간은 카카오모빌리티 기준이에요.',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _ApiErrorBanner extends StatelessWidget {
  const _ApiErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.coral.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('재시도')),
      ],
    ),
  );
}

class _RealtimeWaitingCard extends StatelessWidget {
  const _RealtimeWaitingCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.divider),
    ),
    child: const Text(
      '고정 관광지 대신 TourAPI 실시간 응답을 기다리고 있어요.',
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _RouteVariantSelector extends StatelessWidget {
  const _RouteVariantSelector({
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final int count;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '최적 큐레이션 루트 5개',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 9),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final active = selected == index;
            return ChoiceChip(
              label: Text('루트 ${index + 1}'),
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onSelected(index),
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? AppTheme.primary : AppTheme.divider,
              ),
              labelStyle: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _ComboStep extends StatelessWidget {
  const _ComboStep({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.onInfo,
    this.onDelete,
  });
  final int number;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onInfo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number단계 · $label',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedIndex,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.expand_more_rounded),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  items: List.generate(
                    options.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(options[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: onInfo,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TourAPI 소개 보기',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: '경유지 삭제',
            onPressed: onDelete,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppTheme.textSecondary,
          ),
      ],
    ),
  );
}

class _HourlyWeatherCard extends StatelessWidget {
  const _HourlyWeatherCard({
    required this.region,
    required this.course,
    required this.loading,
  });

  final String region;
  final Course? course;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final forecasts = course?.hourlyWeather.take(8).toList() ?? const [];
    final rainy = course?.weatherTag == 'RAINY';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rainy ? Icons.umbrella_rounded : Icons.wb_sunny_rounded,
                color: rainy ? const Color(0xFF5B7CFA) : AppTheme.warning,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                '$region 시간대별 날씨',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              const Text(
                '기상청 실시간',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (loading)
            const LinearProgressIndicator(minHeight: 3)
          else if (forecasts.isEmpty)
            Text(
              course == null
                  ? '서버에서 예보를 불러오고 있어요.'
                  : rainy
                  ? '강수 예보가 있어 실내 코스를 우선 추천해요.'
                  : '현재 강수 예정은 없어요.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          else
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: forecasts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final forecast = forecasts[index];
                  return SizedBox(
                    width: 58,
                    child: Column(
                      children: [
                        Text(
                          forecast.time,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          forecast.precipitationExpected
                              ? Icons.water_drop_rounded
                              : Icons.wb_sunny_outlined,
                          size: 18,
                          color: forecast.precipitationExpected
                              ? const Color(0xFF5B7CFA)
                              : AppTheme.warning,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${forecast.temperature}°',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '강수 ${forecast.precipitationProbability}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotDetailSheet extends StatelessWidget {
  const _SpotDetailSheet({
    required this.name,
    required this.category,
    required this.spot,
    required this.details,
  });

  final String name;
  final String category;
  final CourseSpot? spot;
  final Future<Map<String, dynamic>?> details;

  String _plainText(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.86,
    ),
    padding: EdgeInsets.fromLTRB(
      22,
      12,
      22,
      24 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (spot?.imageUrl case final imageUrl?)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (spot?.imageUrl != null) const SizedBox(height: 18),
          Text(
            category,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontFamily: AppTheme.gowunDodum,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: details,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                );
              }
              final detail = snapshot.data;
              final overview = _plainText(detail?['overview'] as String? ?? '');
              final address = detail?['address'] as String? ?? spot?.address;
              final telephone = _plainText(
                detail?['telephone'] as String? ?? '',
              );
              final homepage = _plainText(detail?['homepage'] as String? ?? '');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview.isNotEmpty
                        ? overview
                        : '한국관광공사 TourAPI에서 제공한 장소입니다.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  if (address?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 17,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (telephone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailInfoRow(icon: Icons.phone_outlined, text: telephone),
                  ],
                  if (homepage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailInfoRow(
                      icon: Icons.language_rounded,
                      text: homepage,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                size: 17,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  spot?.source ?? 'TOUR_API_REALTIME',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: SelectableText(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
    ],
  );
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 40),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 22,
        child: VerticalDivider(width: 2, thickness: 2, color: AppTheme.divider),
      ),
    ),
  );
}

class _RegionCombo {
  const _RegionCombo({
    required this.code,
    required this.name,
    required this.duration,
    required this.sights,
    required this.foods,
    required this.healing,
    required this.activities,
    required this.cafes,
  });
  final String code;
  final String name;
  final String duration;
  final List<String> sights;
  final List<String> foods;
  final List<String> healing;
  final List<String> activities;
  final List<String> cafes;
}

const _combos = [
  _RegionCombo(
    code: 'NONSAN',
    name: '논산',
    duration: '약 4시간 20분',
    sights: ['선샤인 스튜디오', '탑정호 출렁다리', '관촉사', '돈암서원', '강경근대역사문화거리'],
    foods: ['황산옥', '태능초가집갈비', '연산시장 순대', '삼동소바 논산점'],
    healing: ['탑정호', '관촉사', '돈암서원'],
    activities: ['탑정호 출렁다리', '강경근대역사문화거리', '선샤인 스튜디오'],
    cafes: ['강경구락부', '알바노', '카페 아늑'],
  ),
  _RegionCombo(
    code: 'GONGJU',
    name: '공주',
    duration: '약 4시간 40분',
    sights: [
      '무령왕릉과 왕릉원',
      '공산성',
      '국립공주박물관',
      '공주한옥마을',
      '석장리박물관',
      '계룡산도예촌',
      '계룡산자연사박물관',
      '박동진판소리전수관',
      '동학사',
    ],
    foods: ['동해원', '금강관', '새이학가든', '신흥면옥'],
    healing: ['동학사', '공주한옥마을'],
    activities: ['계룡산도예촌', '석장리박물관'],
    cafes: ['베이커리 인화당', '하루카페&밤떡명가'],
  ),
  _RegionCombo(
    code: 'BUYEO',
    name: '부여',
    duration: '약 5시간',
    sights: [
      '백제문화단지',
      '성흥산성 사랑나무',
      '부소산성',
      '국립부여박물관',
      '정림사지박물관',
      '부여 왕릉원(능산리고분군)',
      '서동요테마파크',
      '부여 가림성',
      '무량사',
      '궁남지',
      '황포돛배',
    ],
    foods: ['장원막국수', '엄가네곰탕', '삼정식당', '나루터식당', '백제향'],
    healing: ['궁남지', '성흥산성 사랑나무', '무량사'],
    activities: ['황포돛배', '서동요테마파크', '부여 가림성'],
    cafes: ['카페 수북로1945', '무드빌리지'],
  ),
];

class _NonsanEntryCard extends StatelessWidget {
  const _NonsanEntryCard({
    required this.party,
    required this.duration,
    required this.routeTemplate,
    required this.course,
    required this.onEdit,
  });

  final TravelParty party;
  final TripDuration duration;
  final RouteTemplate routeTemplate;
  final Course? course;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flag_rounded, color: Colors.white),
            SizedBox(width: 9),
            Text(
              '논산 여정의 기준 · 육군훈련소',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '입영 대상에 따라 훈련소 도착 전후 코스를 다르게 구성해요.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        party.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${party == TravelParty.companion ? '${duration.label} · ' : ''}${routeTemplate.typeLabel} ${routeTemplate.title}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (party != TravelParty.traveler) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${course?.recommendedStartTime ?? '--:--'} 출발 권장  →  '
              '${course?.targetArrivalTime ?? '13:00'} 훈련소 도착',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'GPS와 훈련소까지의 거리 계산은 기기 안에서만 처리돼요.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({required this.concepts, required this.onEdit});

  final Set<TravelConcept> concepts;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: concepts
              .map(
                (concept) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softMint,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    concept.label,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      TextButton(onPressed: onEdit, child: const Text('취향 변경')),
    ],
  );
}

class _ConceptCatalog extends StatelessWidget {
  const _ConceptCatalog({required this.combo, required this.concepts});

  final _RegionCombo combo;
  final Set<TravelConcept> concepts;

  @override
  Widget build(BuildContext context) {
    final entries = <(TravelConcept, List<String>)>[
      (TravelConcept.healing, combo.healing),
      (TravelConcept.activity, combo.activities),
      (TravelConcept.history, combo.sights),
      (TravelConcept.food, combo.foods),
      (TravelConcept.cafe, combo.cafes),
    ].where((entry) => concepts.contains(entry.$1)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '선택한 취향의 실제 장소',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                '${entry.$1.label}  ·  ${entry.$2.join(' · ')}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
