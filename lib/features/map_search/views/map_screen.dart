import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../home_curation/models/course.dart';
import '../../home_curation/models/selected_route.dart';
import '../viewmodels/journey_progress_provider.dart';
import '../models/place.dart';

const _regionCenters = {
  'NONSAN': ll.LatLng(36.1119731, 127.1083526),
  'GONGJU': ll.LatLng(36.4465, 127.1191),
  'BUYEO': ll.LatLng(36.2757, 126.9100),
};

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.initialRoute, this.tileProvider});

  final SelectedRoute? initialRoute;
  final fm.TileProvider? tileProvider;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = fm.MapController();
  bool _locating = false;
  bool _loadingRoadRoute = false;
  bool _tileUnavailable = false;
  int _tileRevision = 0;
  bool _mapReady = false;
  int _routeGeneration = 0;
  String? _requestedRouteSignature;
  String? _displayedRouteSignature;
  bool _hasStraightConnections = true;
  List<ll.LatLng> _roadPoints = const [];
  List<RouteGuideStep> _routeGuides = const [];

  SelectedRoute? get _selectedRoute =>
      ref.read(selectedRouteProvider) ?? widget.initialRoute;

  String? _signature(SelectedRoute? route) =>
      route?.spots.map((s) => '${s.id}:${s.latitude}:${s.longitude}').join('|');

  @override
  void initState() {
    super.initState();
    // Neither tile loading nor GPS permission should delay the route request.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSelectedRoute();
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.initialRoute) != _signature(widget.initialRoute)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelectedRoute();
      });
    }
  }

  void _initializeMap() {
    if (!mounted) return;
    _mapReady = true;
    _fitSelectedRoute();
    _moveToCurrentLocation(searchNearby: _selectedRoute == null);
  }

  void _fitPoints(List<ll.LatLng> points) {
    if (!_mapReady || points.isEmpty) return;
    final size = _mapController.camera.nonRotatedSize;
    _mapController.fitCamera(
      fm.CameraFit.bounds(
        bounds: fm.LatLngBounds.fromPoints(points),
        maxZoom: 16,
        padding: EdgeInsets.fromLTRB(32, size.y * 0.26, 32, size.y * 0.34),
      ),
    );
  }

  void _fitSelectedRoute() {
    final route = _selectedRoute;
    if (route == null) return;
    _fitPoints([
      ...route.spots
          .map(Place.fromCourseSpot)
          .where(_hasValidCoordinates)
          .map((p) => ll.LatLng(p.lat, p.lng)),
      if (_displayedRouteSignature == _signature(route)) ..._roadPoints,
    ]);
  }

  void _syncSelectedRoute() {
    final route = _selectedRoute;
    final signature = _signature(route);
    if (signature == _requestedRouteSignature) return;
    _requestedRouteSignature = signature;
    ++_routeGeneration;
    setState(() {
      _roadPoints = const [];
      _routeGuides = const [];
      _displayedRouteSignature = null;
      _hasStraightConnections = true;
      _loadingRoadRoute = false;
    });
    _fitSelectedRoute();
    if (route != null && route.spots.length >= 2) _loadRoadRoute(route);
  }

  @override
  void dispose() {
    ++_routeGeneration;
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadRoute(SelectedRoute route) async {
    final generation = ++_routeGeneration;
    setState(() => _loadingRoadRoute = true);
    try {
      final metrics = await ref
          .read(courseRepositoryProvider)
          .previewRoute(route.spots);
      if (!mounted ||
          generation != _routeGeneration ||
          _signature(_selectedRoute) != _signature(route)) {
        return;
      }
      final roadPoints = metrics.path
          .where(
            (p) =>
                p.latitude.isFinite &&
                p.longitude.isFinite &&
                p.latitude.abs() <= 90 &&
                p.longitude.abs() <= 180 &&
                !(p.latitude == 0 && p.longitude == 0),
          )
          .map((p) => ll.LatLng(p.latitude, p.longitude))
          .toList();
      setState(() {
        _roadPoints = roadPoints;
        _routeGuides = metrics.guides;
        _displayedRouteSignature = _signature(route);
        _hasStraightConnections =
            metrics.usesStraightConnections || roadPoints.length < 2;
      });
      _fitSelectedRoute();
    } catch (_) {
      if (mounted && generation == _routeGeneration) {
        setState(() => _hasStraightConnections = true);
      }
    } finally {
      if (mounted && generation == _routeGeneration) {
        setState(() => _loadingRoadRoute = false);
      }
    }
  }

  void _showRouteGuides() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text(
                      '카카오 실시간 도로 안내',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routeGuides.length,
                  separatorBuilder: (_, _) => const Divider(height: 18),
                  itemBuilder: (context, index) {
                    final guide = _routeGuides[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.softMint,
                        foregroundColor: AppTheme.primary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        guide.instruction,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: guide.distanceMeters > 0
                          ? Text(_formatGuideDistance(guide.distanceMeters))
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _search() =>
      ref.read(mapSearchViewModelProvider.notifier).searchNearby();

  void _onTileError() {
    if (_tileUnavailable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileUnavailable) setState(() => _tileUnavailable = true);
    });
  }

  void _retryTiles() {
    setState(() {
      _tileUnavailable = false;
      _tileRevision++;
    });
  }

  void _moveToRegion(String region) {
    final center = _regionCenters[region]!;
    ref.read(mapSearchViewModelProvider.notifier).setRegion(region);
    _mapController.move(center, 12);
    _search();
  }

  void _showPlace(BuildContext context, Place place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (place.imageUrl?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  place.imageUrl!,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (place.imageUrl?.isNotEmpty == true) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontFamily: AppTheme.gowunDodum,
                      fontSize: 23,
                    ),
                  ),
                ),
                if (place.scheduledTime case final time?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softCoral,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: AppTheme.coral,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            if (place.address?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                place.address!,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            if (place.petFriendly) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets_rounded, size: 15, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      '반려동물 동반 정보 제공 장소',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _moveToCurrentLocation({bool searchNearby = true}) async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationUtilProvider)
          .getCurrentPosition();
      if (!mounted) return;
      ref
          .read(mapSearchViewModelProvider.notifier)
          .applyDeviceLocation(position.lat, position.lng);
      if (searchNearby) await _search();
      if (!mounted) return;
      if (searchNearby) {
        _mapController.move(ll.LatLng(position.lat, position.lng), 14);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재 위치 주변을 보여드릴게요.')));
      }
    } catch (_) {
      if (!mounted) return;
      if (searchNearby) await _search();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한을 허용하면 내 주변 장소를 찾을 수 있어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openNavigation(CourseSpot spot) async {
    final uri = Uri.parse(
      'https://map.kakao.com/link/to/${Uri.encodeComponent(spot.name)},'
      '${spot.latitude},${spot.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('길안내 앱을 열지 못했어요.')));
    }
  }

  Future<void> _confirmArrival(CourseSpot spot) async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationUtilProvider)
          .getCurrentPosition();
      final distance = const ll.Distance().as(
        ll.LengthUnit.Meter,
        ll.LatLng(position.lat, position.lng),
        ll.LatLng(spot.latitude, spot.longitude),
      );
      if (!mounted) return;
      if (distance > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '목적지까지 약 ${distance.round()}m 남았어요. 500m 안에서 완료할 수 있어요.',
            ),
          ),
        );
        return;
      }
      final finished = await ref
          .read(journeyProgressProvider.notifier)
          .completeCurrentStop();
      if (!mounted) return;
      if (finished) {
        await ref.read(myHistoryViewModelProvider.notifier).loadHistory();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코스를 완주했어요. 영수증과 스탬프가 기록됐습니다!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('방문 완료! 다음 장소로 이동해보세요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('도착 확인을 위해 위치 권한을 허용해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool _sameRoute(SelectedRoute first, SelectedRoute second) {
    if (first.spots.length != second.spots.length) return false;
    for (var index = 0; index < first.spots.length; index++) {
      if (first.spots[index].id != second.spots[index].id) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedRouteProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelectedRoute();
      });
    });
    final state = ref.watch(mapSearchViewModelProvider);
    final selectedRoute =
        ref.watch(selectedRouteProvider) ?? widget.initialRoute;
    final journey = ref.watch(journeyProgressProvider);
    final activeJourney =
        selectedRoute != null &&
            journey != null &&
            _sameRoute(selectedRoute, journey.route)
        ? journey
        : null;
    final places = selectedRoute == null
        ? state.places
        : selectedRoute.spots.map(Place.fromCourseSpot).toList();
    final mappablePlaces = places.where(_hasValidCoordinates).toList();
    final points = mappablePlaces
        .map((place) => ll.LatLng(place.lat, place.lng))
        .toList();
    final routePoints =
        _displayedRouteSignature == _signature(selectedRoute) &&
            _roadPoints.length > 1
        ? _roadPoints
        : points;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: fm.FlutterMap(
              mapController: _mapController,
              options: fm.MapOptions(
                initialCenter: points.isNotEmpty
                    ? points.first
                    : const ll.LatLng(36.4465, 127.1191),
                initialZoom: 12,
                backgroundColor: const Color(0xFFF0F4F0),
                maxZoom: 19,
                onMapReady: _initializeMap,
              ),
              children: [
                fm.TileLayer(
                  key: ValueKey(_tileRevision),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // flutter_map's provider owns cancellation, HTTP status and
                  // decoding. A CachedNetworkImageProvider here could leave the
                  // whole native map blank when a tile request was cancelled.
                  tileProvider: widget.tileProvider ?? fm.NetworkTileProvider(),
                  maxNativeZoom: 19,
                  panBuffer: 0,
                  userAgentPackageName: 'com.techtour.flutterprojects',
                  errorTileCallback: (_, _, _) => _onTileError(),
                  evictErrorTileStrategy:
                      fm.EvictErrorTileStrategy.notVisibleRespectMargin,
                ),
                if (routePoints.length > 1)
                  fm.PolylineLayer(
                    polylines: [
                      fm.Polyline(
                        points: routePoints,
                        color: AppTheme.primary,
                        strokeWidth: 5,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                fm.MarkerLayer(
                  markers: [
                    ...mappablePlaces.asMap().entries.map((entry) {
                      final place = entry.value;
                      return fm.Marker(
                        point: ll.LatLng(place.lat, place.lng),
                        width: 46,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => _showPlace(context, place),
                          child: _PlaceMarker(number: entry.key + 1),
                        ),
                      );
                    }),
                    if (state.currentLat != null && state.currentLng != null)
                      fm.Marker(
                        point: ll.LatLng(state.currentLat!, state.currentLng!),
                        width: 24,
                        height: 24,
                        child: const _CurrentLocationMarker(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedRoute?.title ?? '내 주변 콤보',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                selectedRoute == null
                                    ? '현재 위치에서 가까운 여행지를 연결했어요'
                                    : '선택한 ${selectedRoute.spots.length}곳을 순서대로 연결했어요',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _locating
                              ? null
                              : () => _moveToCurrentLocation(
                                  searchNearby: selectedRoute == null,
                                ),
                          tooltip: '현 위치로 이동',
                          icon: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedRoute == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _RegionChip(
                          label: '논산',
                          value: 'NONSAN',
                          selected: state.region,
                          onTap: _moveToRegion,
                        ),
                        _RegionChip(
                          label: '공주',
                          value: 'GONGJU',
                          selected: state.region,
                          onTap: _moveToRegion,
                        ),
                        _RegionChip(
                          label: '부여',
                          value: 'BUYEO',
                          selected: state.region,
                          onTap: _moveToRegion,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: '반려동물',
                          icon: Icons.pets_rounded,
                          selected: state.petFriendly,
                          onTap: () {
                            ref
                                .read(mapSearchViewModelProvider.notifier)
                                .togglePetFriendly(!state.petFriendly);
                            _search();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (selectedRoute == null && state.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _ApiErrorBanner(
                    message: state.errorMessage!,
                    onRetry: _search,
                  ),
                ],
                if (_tileUnavailable) ...[
                  const SizedBox(height: 8),
                  _ApiErrorBanner(
                    message: '배경 지도를 불러오지 못했어요. 코스 위치와 연결선은 유지됩니다.',
                    onRetry: _retryTiles,
                  ),
                ],
                if (selectedRoute != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loadingRoadRoute
                                  ? '경유지를 연결했어요 · 카카오 도로 경로 조회 중'
                                  : _hasStraightConnections
                                  ? '경유지 순서대로 직선 연결 · 실제 도로와 다를 수 있어요'
                                  : '카카오 도로 경로로 연결했어요',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          IconButton(
                            tooltip: '전체 코스 보기',
                            onPressed: _fitSelectedRoute,
                            icon: const Icon(
                              Icons.zoom_out_map_rounded,
                              size: 18,
                            ),
                          ),
                          if (!_loadingRoadRoute && _hasStraightConnections)
                            IconButton(
                              tooltip: '도로 경로 재시도',
                              onPressed: () => _loadRoadRoute(selectedRoute),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                if (selectedRoute != null)
                  _JourneyControlCard(
                    progress: activeJourney,
                    route: selectedRoute,
                    locating: _locating,
                    onStart: () => ref
                        .read(journeyProgressProvider.notifier)
                        .start(selectedRoute),
                    onNavigate: _openNavigation,
                    onConfirm: _confirmArrival,
                    loadingRoadRoute: _loadingRoadRoute,
                    onShowGuides: _routeGuides.isEmpty
                        ? null
                        : _showRouteGuides,
                  ),
                _RoutePreview(
                  places: places,
                  isLoading: selectedRoute == null && state.isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValidCoordinates(Place place) =>
      place.lat.isFinite &&
      place.lng.isFinite &&
      place.lat >= -90 &&
      place.lat <= 90 &&
      place.lng >= -180 &&
      place.lng <= 180 &&
      !(place.lat == 0 && place.lng == 0);
}

class _JourneyControlCard extends StatelessWidget {
  const _JourneyControlCard({
    required this.progress,
    required this.route,
    required this.locating,
    required this.onStart,
    required this.onNavigate,
    required this.onConfirm,
    required this.loadingRoadRoute,
    required this.onShowGuides,
  });

  final JourneyProgress? progress;
  final SelectedRoute route;
  final bool locating;
  final VoidCallback onStart;
  final ValueChanged<CourseSpot> onNavigate;
  final ValueChanged<CourseSpot> onConfirm;
  final bool loadingRoadRoute;
  final VoidCallback? onShowGuides;

  @override
  Widget build(BuildContext context) {
    final current = progress?.currentSpot;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: progress == null
          ? Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '코스 여행 시작',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'GPS 방문 확인과 실제 도로 경로로 진행해요.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                  ),
                  child: const Text('시작'),
                ),
              ],
            )
          : progress!.completed
          ? const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '완주 완료 · 내 정보에 기록되었습니다.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${progress!.currentIndex + 1}/${route.spots.length} 다음 목적지',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  current!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (loadingRoadRoute) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        '카카오 도로 경로 계산 중',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ] else if (onShowGuides != null) ...[
                  const SizedBox(height: 3),
                  TextButton.icon(
                    onPressed: onShowGuides,
                    icon: const Icon(Icons.alt_route_rounded, size: 16),
                    label: const Text('전체 도로 안내 보기'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigate(current),
                        icon: const Icon(Icons.navigation_rounded, size: 17),
                        label: const Text('길안내'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: locating ? null : () => onConfirm(current),
                        icon: locating
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.location_on_rounded, size: 17),
                        label: const Text('도착 확인'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ApiErrorBanner extends StatelessWidget {
  const _ApiErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4EF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFC7B2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB54708)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7A2E0E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('재시도')),
      ],
    ),
  );
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(value),
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: active ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : AppTheme.textSecondary,
      ),
      label: Text(label),
      selectedColor: AppTheme.accent,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      '$number',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
    ),
  );
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.places, required this.isLoading});
  final List<Place> places;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '오늘의 연결 코스',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${places.length}곳',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '조건에 맞는 장소를 찾고 있어요.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 68,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: places.asMap().entries.expand<Widget>((entry) {
                  final widgets = <Widget>[
                    SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.softMint,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.value.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (entry.value.formattedDistance
                              case final distance?)
                            Text(
                              distance,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ];
                  if (entry.key < places.length - 1) {
                    widgets.add(
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    );
                  }
                  return widgets;
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF3478F6),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 7),
      ],
    ),
  );
}

String _formatGuideDistance(int meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)}km 이동'
    : '${meters}m 이동';
