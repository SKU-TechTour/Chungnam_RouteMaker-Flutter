import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/map_search_state.dart';
import '../views/kakao_map_widget.dart';

const _regionCenters = {
  'NONSAN': ll.LatLng(36.1119731, 127.1083526),
  'GONGJU': ll.LatLng(36.4465, 127.1191),
  'BUYEO': ll.LatLng(36.2757, 126.9100),
};

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = fm.MapController();
  Object? _kakaoController;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(mapSearchViewModelProvider.notifier).searchNearby(),
    );
  }

  Future<void> _search() =>
      ref.read(mapSearchViewModelProvider.notifier).searchNearby();

  void _moveToRegion(String region) {
    final center = _regionCenters[region]!;
    ref.read(mapSearchViewModelProvider.notifier).setRegion(region);
    if (kIsWeb) {
      _mapController.move(center, 12);
    } else {
      moveKakaoMap(_kakaoController, center.latitude, center.longitude);
    }
    _search();
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationUtilProvider)
          .getCurrentPosition();
      ref
          .read(mapSearchViewModelProvider.notifier)
          .applyDeviceLocation(position.lat, position.lng);
      if (kIsWeb) {
        _mapController.move(ll.LatLng(position.lat, position.lng), 14);
      } else {
        moveKakaoMap(_kakaoController, position.lat, position.lng);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재 위치 주변을 보여드릴게요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한을 허용하면 내 주변 장소를 찾을 수 있어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapSearchViewModelProvider);
    final points = state.places
        .map((place) => ll.LatLng(place.lat, place.lng))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? fm.FlutterMap(
                    mapController: _mapController,
                    options: const fm.MapOptions(
                      initialCenter: ll.LatLng(36.4465, 127.1191),
                      initialZoom: 12,
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.skutechtour.routemaker',
                      ),
                      if (points.length > 1)
                        fm.PolylineLayer(
                          polylines: [
                            fm.Polyline(
                              points: points,
                              color: AppTheme.primary,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      fm.MarkerLayer(
                        markers: [
                          ...state.places.asMap().entries.map((entry) {
                            final place = entry.value;
                            return fm.Marker(
                              point: ll.LatLng(place.lat, place.lng),
                              width: 46,
                              height: 46,
                              child: _PlaceMarker(number: entry.key + 1),
                            );
                          }),
                          if (state.currentLat != null &&
                              state.currentLng != null)
                            fm.Marker(
                              point: ll.LatLng(
                                state.currentLat!,
                                state.currentLng!,
                              ),
                              width: 24,
                              height: 24,
                              child: const _CurrentLocationMarker(),
                            ),
                        ],
                      ),
                    ],
                  )
                : buildKakaoMap(
                    state: state,
                    onCreated: (controller) =>
                        setState(() => _kakaoController = controller),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '내 주변 콤보',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '현재 위치에서 가까운 여행지를 연결했어요',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _locating ? null : _moveToCurrentLocation,
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
                        label: '유모차 가능',
                        icon: Icons.baby_changing_station,
                        selected: state.strollerAccessible,
                        onTap: () {
                          ref
                              .read(mapSearchViewModelProvider.notifier)
                              .toggleStrollerAccessible(
                                !state.strollerAccessible,
                              );
                          _search();
                        },
                      ),
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
                        label: '대형 주차장',
                        icon: Icons.local_parking_rounded,
                        selected: state.parking,
                        onTap: () {
                          ref
                              .read(mapSearchViewModelProvider.notifier)
                              .toggleParking(!state.parking);
                          _search();
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _RoutePreview(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  const _RoutePreview({required this.state});
  final MapSearchState state;

  @override
  Widget build(BuildContext context) {
    final places = state.places;
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
              if (state.isLoading)
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
            Row(
              children: places.take(3).toList().asMap().entries.expand<Widget>((
                entry,
              ) {
                final widgets = <Widget>[
                  Expanded(
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
                        if (entry.value.formattedDistance case final distance?)
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
                if (entry.key < places.take(3).length - 1) {
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
