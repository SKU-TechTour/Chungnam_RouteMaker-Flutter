import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_util.dart';
import '../../../core/widgets/external_map_buttons.dart';
import '../../home_curation/models/course.dart';
import '../../home_curation/models/selected_route.dart';
import '../../saved/models/saved_place.dart';
import '../../saved/viewmodels/saved_places_provider.dart';
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
  Timer? _roadRouteTimer;
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
    // 선택 코스는 GPS 권한과 무관하게 즉시 표시한다. 주변 지도도 선택된
    // 지역 중심에서 먼저 열고, GPS는 사용자가 현 위치 버튼을 누를 때만 쓴다.
    if (_selectedRoute == null) {
      unawaited(_search());
    }
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
    if (route != null && route.spots.length >= 2) {
      // 먼저 선택 경유지와 직선 연결을 한 프레임 그린 뒤 도로 경로를
      // 요청한다. 네트워크/JSON 처리가 지도 첫 화면을 막지 않게 한다.
      _roadRouteTimer?.cancel();
      _roadRouteTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted && _signature(_selectedRoute) == signature) {
          _loadRoadRoute(route);
        }
      });
    }
  }

  @override
  void dispose() {
    ++_routeGeneration;
    _roadRouteTimer?.cancel();
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
      final allRoadPoints = metrics.path
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
      final roadPoints = _limitPathPoints(allRoadPoints);
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
    final region = ref.read(mapSearchViewModelProvider).region;
    final savedPlace = SavedPlace.fromPlace(place, region);
    final audioGuide = int.tryParse(place.id) != null
        ? ref.read(courseRepositoryProvider).fetchAudioGuide(place.name)
        : Future<Map<String, dynamic>?>.value(null);
    final congestion = int.tryParse(place.id) != null
        ? ref.read(courseRepositoryProvider).fetchSpotCongestion(
            region: region,
            attractionName: place.name,
          )
        : Future<Map<String, dynamic>?>.value(null);
    final petInfo = place.petFriendly && int.tryParse(place.id) != null
        ? ref.read(placeRepositoryProvider).fetchPetInfo(place.id)
        : Future<Map<String, dynamic>?>.value(null);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isSaved = ref
              .read(savedPlacesProvider)
              .any((item) => item.storageKey == savedPlace.storageKey);
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 14),
                  if (place.imageUrl?.isNotEmpty == true) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        place.imageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontFamily: AppTheme.gowunDodum,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: isSaved ? '장소 찜 해제' : '장소 찜하기',
                        onPressed: () {
                          ref
                              .read(savedPlacesProvider.notifier)
                              .toggle(savedPlace);
                          setSheetState(() {});
                        },
                        icon: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (place.scheduledTime case final time?)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softCoral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            time,
                            style: const TextStyle(
                              color: AppTheme.coral,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (place.address?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      place.address!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  if (place.petFriendly) ...[
                    const SizedBox(height: 10),
                    _PetFriendlyInformation(information: petInfo),
                  ],
                  if (int.tryParse(place.id) case final contentId?
                      when contentId > 0) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MapCongestionBadge(congestion: congestion),
                        OutlinedButton.icon(
                          onPressed: () => _showAccessibility(context, place),
                          icon: const Icon(Icons.accessible_forward_rounded),
                          label: const Text('이동 편의 정보'),
                        ),
                        _MapAudioGuideButton(audioGuide: audioGuide),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  ExternalMapButtons(
                    name: place.name,
                    latitude: place.lat,
                    longitude: place.lng,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAccessibility(BuildContext context, Place place) {
    final information = ref
        .read(placeRepositoryProvider)
        .fetchAccessibility(place.id);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.accessible_forward_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('이동 편의 정보'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: information,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 12),
                    Text('무장애 여행 정보를 확인하고 있어요.'),
                  ],
                );
              }
              final data = snapshot.data;
              final available = data?['available'] as bool? ?? false;
              final features = (data?['features'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .toList(growable: false);
              if (snapshot.hasError || !available || features.isEmpty) {
                return Text(
                  data?['message'] as String? ?? '제공되는 이동 편의 정보가 없습니다.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: features.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  final provided = feature['provided'] as bool? ?? false;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        provided
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: provided
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${feature['label']}\n${feature['value']}',
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToCurrentLocation({bool searchNearby = true}) async {
    if (!await _ensureLocationPermission()) {
      if (searchNearby) await _search();
      return;
    }
    if (!mounted) return;
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
    } on LocationServiceDisabledException {
      if (!mounted) return;
      if (searchNearby) await _search();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기의 위치 서비스를 켠 뒤 다시 시도해주세요.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (searchNearby) await _search();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해주세요.')),
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
    if (!await _ensureLocationPermission()) return;
    if (!mounted) return;
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

  Future<bool> _ensureLocationPermission() async {
    final location = ref.read(locationUtilProvider);
    final status = await location.permissionStatus();
    if (!mounted) return false;
    if (status == AppLocationPermission.granted) return true;
    if (status == AppLocationPermission.deniedForever) {
      await _showLocationSettingsDialog();
      return false;
    }

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.location_on_outlined,
          color: AppTheme.primary,
          size: 34,
        ),
        title: const Text(
          '위치 접근 권한 안내',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Chip(
                avatar: Icon(Icons.check_circle_outline_rounded, size: 17),
                label: Text(
                  '선택 권한',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SizedBox(height: 12),
            _PermissionNoticeRow(
              title: '사용 목적',
              description: '현재 위치 주변 관광지 안내와 코스 방문·완주 확인',
            ),
            SizedBox(height: 12),
            _PermissionNoticeRow(
              title: '처리 방식',
              description: 'GPS 좌표는 기기 안에서 거리 계산에만 사용하며 서버로 전송하거나 저장하지 않아요.',
            ),
            SizedBox(height: 12),
            _PermissionNoticeRow(
              title: '거부해도 괜찮아요',
              description: '관광정보·추천 코스·찜은 계속 이용할 수 있고, 주변 정렬과 도착 확인만 제한돼요.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('동의하고 계속'),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return false;

    final requested = await location.requestPermission();
    if (!mounted) return false;
    if (requested == AppLocationPermission.granted) return true;
    if (requested == AppLocationPermission.deniedForever) {
      await _showLocationSettingsDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한 없이도 지역별 관광정보를 둘러볼 수 있어요.')),
      );
    }
    return false;
  }

  Future<void> _showLocationSettingsDialog() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('위치 권한이 꺼져 있어요'),
        content: const Text(
          '현재 위치 주변 장소와 방문 완료 기능을 사용하려면 앱 설정에서 위치 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await ref.read(locationUtilProvider).openAppSettings();
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
                if (selectedRoute != null && routePoints.length > 1)
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
                if (selectedRoute != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                                  selectedRoute.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '선택한 ${selectedRoute.spots.length}곳을 순서대로 연결했어요',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
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
                        _FilterChip(
                          label: '이동 편의',
                          icon: Icons.accessible_forward_rounded,
                          selected: state.movementConvenience,
                          onTap: () {
                            ref
                                .read(mapSearchViewModelProvider.notifier)
                                .toggleMovementConvenience(
                                  !state.movementConvenience,
                                );
                            _search();
                          },
                        ),
                      ],
                    ),
                  ),
                  if (state.petFriendly)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TourAPI에서 반려동물 동반 정보가 확인된 ${state.places.length}곳만 표시해요.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                if (selectedRoute != null)
                  _RoutePreview(places: places, isLoading: false),
              ],
            ),
          ),
          if (selectedRoute == null)
            Positioned(
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'current-location',
                  tooltip: '현 위치로 이동',
                  onPressed: _locating ? null : () => _moveToCurrentLocation(),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
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

  List<ll.LatLng> _limitPathPoints(List<ll.LatLng> points) {
    const maximum = 700;
    if (points.length <= maximum) return points;
    final stride = (points.length / (maximum - 1)).ceil();
    final reduced = <ll.LatLng>[
      for (var index = 0; index < points.length - 1; index += stride)
        points[index],
      points.last,
    ];
    return reduced;
  }
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
                    // The app-wide button theme uses Size.fromHeight, whose
                    // width is infinite. This button lives in a Row, so it
                    // needs a finite width constraint or the entire map page
                    // fails layout before markers and polylines can paint.
                    minimumSize: const Size(68, 44),
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
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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

class _PetFriendlyInformation extends StatelessWidget {
  const _PetFriendlyInformation({required this.information});

  final Future<Map<String, dynamic>?> information;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: information,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Chip(
          avatar: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text('반려동물 동반 정보 확인 중'),
        );
      }
      final data = snapshot.data;
      final detail = data?['detail'] as String?;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF4D79B)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.pets_rounded, size: 18, color: Color(0xFF9B650D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                detail?.trim().isNotEmpty == true
                    ? detail!
                    : '한국관광공사에 등록된 반려동물 동반 장소입니다.',
                style: const TextStyle(fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _MapCongestionBadge extends StatelessWidget {
  const _MapCongestionBadge({required this.congestion});

  final Future<Map<String, dynamic>?> congestion;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: congestion,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const OutlinedButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('혼잡도 확인 중'),
            ],
          ),
        );
      }
      final data = snapshot.data;
      if (snapshot.hasError || data?['available'] != true) {
        return const SizedBox.shrink();
      }
      final level = data?['level'] as String? ?? '정보 제공';
      final rate = (data?['rate'] as num?)?.toDouble();
      final label = rate == null
          ? '예상 혼잡도 · $level'
          : '예상 혼잡도 · $level ${rate.toStringAsFixed(0)}%';
      return OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('관광지 예상 혼잡도'),
            content: Text(
              '$label\n\n${data?['notice'] ?? '방문 집중률 예측 정보입니다.'}\n'
              '기준일 ${data?['baseDate'] ?? '-'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.groups_2_outlined),
        label: Text(label),
      );
    },
  );
}

class _MapAudioGuideButton extends StatefulWidget {
  const _MapAudioGuideButton({required this.audioGuide});

  final Future<Map<String, dynamic>?> audioGuide;

  @override
  State<_MapAudioGuideButton> createState() => _MapAudioGuideButtonState();
}

class _MapAudioGuideButtonState extends State<_MapAudioGuideButton> {
  final _player = AudioPlayer();
  bool _playing = false;
  String? _loadedUrl;

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle(String url) async {
    try {
      if (_playing) {
        await _player.pause();
      } else {
        if (_loadedUrl != url) {
          await _player.setUrl(url);
          _loadedUrl = url;
        }
        await _player.play();
      }
      if (mounted) setState(() => _playing = !_playing);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오디오 해설을 재생하지 못했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: widget.audioGuide,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const OutlinedButton(
          onPressed: null,
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final url = snapshot.data?['audioUrl'] as String? ?? '';
      if (url.isEmpty) {
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.headphones_rounded),
          label: const Text('오디오 해설 없음'),
        );
      }
      return OutlinedButton.icon(
        onPressed: () => _toggle(url),
        icon: Icon(_playing ? Icons.pause_rounded : Icons.headphones_rounded),
        label: Text(_playing ? '일시정지' : '오디오 해설'),
      );
    },
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

class _PermissionNoticeRow extends StatelessWidget {
  const _PermissionNoticeRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 3),
        child: Icon(Icons.circle, size: 7, color: AppTheme.accent),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
            children: [
              TextSpan(
                text: '$title\n',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(text: description),
            ],
          ),
        ),
      ),
    ],
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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
          const SizedBox(height: 6),
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
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: places.asMap().entries.expand<Widget>((entry) {
                  final widgets = <Widget>[
                    SizedBox(
                      width: 118,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.softMint,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.value.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
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
