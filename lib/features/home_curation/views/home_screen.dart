import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const _publicDataNoticeHiddenUntilKey =
      'public_data_notice_hidden_until';
  static bool _noticeShownThisSession = false;

  var _regionIndex = 0;
  var _party = TravelParty.traveler;
  var _duration = TripDuration.dayTrip;
  var _routeTemplate = RouteTemplate.travelerFlexible;
  Set<TravelConcept> _concepts = TravelConcept.values.toSet();
  List<CourseSpot> _editableSpots = [];
  var _selectedVariant = 0;
  RouteMetrics? _previewMetrics;
  bool _routeUpdating = false;
  int _loadGeneration = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  Future<void> _initializeHome() async {
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
    final canReuseSession =
        existing != null &&
        (preferences == null ||
            existing.preferenceSignature ==
                travelPreferenceSignature(preferences));

    // 공공데이터 안내를 읽는 동안 API 요청을 먼저 시작한다. 안내 확인 뒤에도
    // 응답이 남아 있을 때만 진행률 팝업을 이어서 보여준다.
    final pendingLoad = canReuseSession ? null : _loadRegion();
    await _showPublicDataNoticeIfNeeded();
    if (!mounted || pendingLoad == null) return;
    await _loadRegionWithDelayedDialog(pendingLoad: pendingLoad);
  }

  Future<void> _showPublicDataNoticeIfNeeded() async {
    if (_noticeShownThisSession || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    final hiddenUntil = DateTime.fromMillisecondsSinceEpoch(
      preferences.getInt(_publicDataNoticeHiddenUntilKey) ?? 0,
    );
    if (DateTime.now().isBefore(hiddenUntil) || !mounted) return;
    _noticeShownThisSession = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primary),
        title: const Text(
          '공공데이터 이용 안내',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '본 앱은 한국관광공사 TourAPI와 기상청 예보 등 공공데이터를 실시간으로 조합해 정보를 제공합니다. 기관의 갱신 시점과 현장 상황에 따라 운영시간, 날씨, 이동 정보가 실제와 다를 수 있으니 방문 전 공식 정보를 한 번 더 확인해주세요.',
              style: TextStyle(height: 1.55),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    await preferences.setInt(
                      _publicDataNoticeHiddenUntilKey,
                      DateTime.now()
                          .add(const Duration(days: 1))
                          .millisecondsSinceEpoch,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('1일간 보지 않기'),
                ),
                const Spacer(),
                SizedBox(
                  width: 104,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _loadRegionWithDelayedDialog({
    bool forceRefresh = false,
    Future<bool>? pendingLoad,
  }) async {
    final progress = ValueNotifier<_InitialLoadProgress>(
      const _InitialLoadProgress(
        value: 0.12,
        message: 'TourAPI로부터 여행 정보를 불러오는 중입니다.',
      ),
    );
    final progressTimer = Timer.periodic(const Duration(milliseconds: 280), (
      _,
    ) {
      final current = progress.value;
      if (current.failed || current.value >= 0.94) return;
      final next = (current.value + 0.018).clamp(0.0, 0.94);
      progress.value = _InitialLoadProgress(
        value: next,
        message: switch (next) {
          < 0.4 => 'TourAPI로부터 여행 정보를 불러오는 중입니다.',
          < 0.7 => '날씨와 이동 정보를 함께 확인하는 중입니다.',
          _ => '취향에 맞는 여행 코스를 정리하는 중입니다.',
        },
      );
    });
    final loadFuture = pendingLoad ?? _loadRegion(forceRefresh: forceRefresh);
    final completedWithinOneSecond = await Future.any<bool>([
      loadFuture.then((_) => true),
      Future<bool>.delayed(const Duration(seconds: 1), () => false),
    ]);

    if (completedWithinOneSecond || !mounted) {
      final loaded = await loadFuture;
      progressTimer.cancel();
      progress.dispose();
      return loaded;
    }

    var dialogOpen = true;
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: _InitialLoadDialog(progress: progress),
      ),
    ).whenComplete(() => dialogOpen = false);
    try {
      final loaded = await loadFuture;
      progressTimer.cancel();
      if (!loaded) {
        progress.value = _InitialLoadProgress(
          value: progress.value.value,
          message: '추천 정보를 불러오지 못했습니다. 화면에서 다시 시도해주세요.',
          failed: true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 900));
        return false;
      }

      progress.value = const _InitialLoadProgress(
        value: 0.97,
        message: '마지막으로 화면을 준비하는 중입니다.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 260));
      progress.value = const _InitialLoadProgress(
        value: 1,
        message: '여행 준비가 완료되었습니다.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 320));
      return true;
    } finally {
      progressTimer.cancel();
      if (mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await dialogFuture;
      progress.dispose();
    }
  }

  TravelPreferences get _preferences => TravelPreferences(
    party: _party,
    concepts: _concepts,
    duration: _duration,
    routeTemplate: _routeTemplate,
  );

  Future<void> _editPreferences() async {
    final updated = await context.push<TravelPreferences>('/preferences');
    if (!mounted || updated == null) return;
    setState(() {
      _party = updated.party;
      _duration = updated.duration;
      _routeTemplate = updated.routeTemplate;
      _concepts = Set.of(updated.concepts);
      _selectedVariant = 0;
      _editableSpots = [];
      _previewMetrics = null;
    });
    await _loadRegionWithDelayedDialog();
  }

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

  Future<bool> _loadRegion({bool forceRefresh = false}) async {
    final generation = ++_loadGeneration;
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
          forceRefresh: forceRefresh,
        );
    if (!mounted || generation != _loadGeneration) return false;
    final state = ref.read(homeCurationViewModelProvider);
    final loaded = state.errorMessage == null && state.courses.isNotEmpty;
    if (loaded) _applyVariant(0, state.courses);
    return loaded;
  }

  void _selectRegion(int index) {
    setState(() {
      _regionIndex = index;
      _selectedVariant = 0;
      _editableSpots = [];
      _previewMetrics = null;
    });
    _persistSession();
    _loadRegionWithDelayedDialog();
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
    ref.read(courseRepositoryProvider).prefetchSpotDetails(selected.spots);
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
    final details = spot != null && spot.source == 'TOUR_API_REALTIME'
        ? ref.read(courseRepositoryProvider).fetchSpotDetails(spot.id)
        : Future<Map<String, dynamic>?>.value(null);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpotDetailSheet(
        name: name,
        category: category,
        spot: spot,
        details: details,
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
    final popularCourses = ref.watch(popularCoursesProvider);
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
                    onRetry: () =>
                        _loadRegionWithDelayedDialog(forceRefresh: true),
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
                      onEdit: _editPreferences,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PreferenceSummary(
                    concepts: _concepts,
                    onEdit: _editPreferences,
                  ),
                  const SizedBox(height: 24),
                  _PopularCoursesSection(
                    courses: popularCourses,
                    onStart: (course) {
                      final route = course.toSelectedRoute();
                      ref.read(selectedRouteProvider.notifier).state = route;
                      context.go('/map');
                    },
                  ),
                  const SizedBox(height: 26),
                  if (curationState.errorMessage != null) ...[
                    _ApiErrorBanner(
                      message: curationState.errorMessage!,
                      onRetry: () =>
                          _loadRegionWithDelayedDialog(forceRefresh: true),
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
                          constraints: const BoxConstraints(maxWidth: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softMint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_concepts.map((concept) => concept.label).join(' · ')} 반영',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ApiConstants.useMockData)
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
                                    : _loadRegionWithDelayedDialog,
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
                                        final route = SelectedRoute(
                                          title:
                                              liveCourse?.title ??
                                              '${_combo.name} 취향 맞춤 코스',
                                          region: _combo.code,
                                          spots: List.unmodifiable(
                                            selectedSpots,
                                          ),
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
                                        ref
                                                .read(
                                                  selectedRouteProvider
                                                      .notifier,
                                                )
                                                .state =
                                            route;
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

class _PopularCoursesSection extends ConsumerWidget {
  const _PopularCoursesSection({required this.courses, required this.onStart});

  final AsyncValue<List<SavedCourse>> courses;
  final ValueChanged<SavedCourse> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: AppTheme.coral),
          SizedBox(width: 8),
          Text(
            '가장 인기 있는 코스 TOP 3',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      const SizedBox(height: 5),
      const Text(
        '여행자들이 실제로 찜한 횟수를 기준으로 보여드려요.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 12),
      courses.when(
        loading: () => const SizedBox(
          height: 76,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => const _PopularCourseEmpty(
          message: '인기 코스를 불러오지 못했어요. 잠시 후 다시 확인해주세요.',
        ),
        data: (items) => items.isEmpty
            ? const _PopularCourseEmpty(message: '첫 번째 인기 코스를 기다리고 있어요.')
            : Column(
                children: items
                    .take(3)
                    .toList(growable: false)
                    .asMap()
                    .entries
                    .map((entry) {
                      final course = entry.value;
                      final isSaved = ref
                          .watch(savedCoursesProvider)
                          .any((saved) => saved.routeKey == course.routeKey);
                      final routeLabel = course.spots
                          .take(3)
                          .map((spot) => spot.name)
                          .join(' → ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: course.spots.length >= 2
                                ? () => onStart(course)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.softCoral,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: AppTheme.coral,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routeLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          '${course.title} · ${course.spots.length}개 경유지',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: isSaved ? '찜 해제' : '이 코스 찜하기',
                                    onPressed: () {
                                      ref
                                          .read(savedCoursesProvider.notifier)
                                          .toggle(course);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isSaved
                                                ? '인기 코스 찜을 해제했어요.'
                                                : '인기 코스를 찜했어요.',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  Text(
                                    '${course.bookmarkCount}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
      ),
    ],
  );
}

class _PopularCourseEmpty extends StatelessWidget {
  const _PopularCourseEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    ),
  );
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
                        '소개보기',
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
    required this.onRetry,
  });

  final String region;
  final Course? course;
  final bool loading;
  final VoidCallback onRetry;

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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '시간대별 예보를 불러오지 못했어요. 다시 확인해주세요.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('재시도')),
              ],
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
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();

  Uri? _homepageUri(String value) {
    final decoded = value.replaceAll('&amp;', '&');
    final href = RegExp(
      r'''href\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(decoded)?.group(1);
    final rawUrl = RegExp(
      r'''https?://[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(decoded)?.group(0);
    final candidate = href ?? rawUrl;
    if (candidate == null) return null;
    final uri = Uri.tryParse(candidate);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri
        : null;
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결된 페이지를 열 수 없어요.')));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).height * 0.82,
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
                return _DelayedDetailLoading(address: spot?.address);
              }
              if (snapshot.hasError) {
                return const _DetailLoadError();
              }
              final detail = snapshot.data;
              final overview = _plainText(detail?['overview'] as String? ?? '');
              final address = detail?['address'] as String? ?? spot?.address;
              final telephone = _plainText(
                detail?['telephone'] as String? ?? '',
              );
              final homepageRaw = detail?['homepage'] as String? ?? '';
              final homepage = _plainText(homepageRaw);
              final homepageUri = _homepageUri(homepageRaw);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview.isNotEmpty
                        ? overview
                        : '한국관광공사 TourAPI 기본 정보에는 이 장소의 장문 소개가 제공되지 않았습니다. 아래 주소와 연락처 등 제공된 정보를 확인해주세요.',
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
                  if (homepageUri != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _openUri(context, homepageUri),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('공식 홈페이지 열기'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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

class _DelayedDetailLoading extends StatefulWidget {
  const _DelayedDetailLoading({this.address});

  final String? address;

  @override
  State<_DelayedDetailLoading> createState() => _DelayedDetailLoadingState();
}

class _DelayedDetailLoadingState extends State<_DelayedDetailLoading> {
  Timer? _timer;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showProgress = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.address?.isNotEmpty == true)
        _DetailInfoRow(icon: Icons.place_outlined, text: widget.address!),
      const SizedBox(height: 14),
      Text(
        _showProgress
            ? 'TourAPI에서 상세 소개와 홈페이지를 확인하고 있어요.'
            : '장소 기본 정보를 먼저 보여드리고 있어요.',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      if (_showProgress) ...[
        const SizedBox(height: 10),
        const LinearProgressIndicator(minHeight: 3),
      ],
    ],
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

class _DetailLoadError extends StatelessWidget {
  const _DetailLoadError();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.coral.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_off_rounded, color: AppTheme.coral, size: 19),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'TourAPI 상세 소개를 불러오지 못했습니다. 네트워크 상태를 확인한 뒤 소개보기를 다시 열어주세요.',
            style: TextStyle(fontSize: 12, height: 1.45),
          ),
        ),
      ],
    ),
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

class _InitialLoadProgress {
  const _InitialLoadProgress({
    required this.value,
    required this.message,
    this.failed = false,
  });

  final double value;
  final String message;
  final bool failed;
}

class _InitialLoadDialog extends StatelessWidget {
  const _InitialLoadDialog({required this.progress});

  final ValueListenable<_InitialLoadProgress> progress;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
    content: ValueListenableBuilder<_InitialLoadProgress>(
      valueListenable: progress,
      builder: (context, state, _) {
        final percent = (state.value * 100).round();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: state.failed
                        ? const Color(0xFFFFEBEE)
                        : AppTheme.softMint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.failed
                        ? Icons.cloud_off_rounded
                        : Icons.route_rounded,
                    color: state.failed
                        ? const Color(0xFFC94545)
                        : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Text(
                    '나만의 충남 루트 준비 중',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              state.message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: state.value),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 9,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: AppTheme.divider,
                color: state.failed
                    ? const Color(0xFFC94545)
                    : state.value >= 1
                    ? AppTheme.accent
                    : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$percent%',
                style: TextStyle(
                  color: state.failed
                      ? const Color(0xFFC94545)
                      : state.value >= 1
                      ? AppTheme.accent
                      : AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
