import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/features/map_search/views/kakao_map_widget.dart';

const _gongjuLat = 36.4465;
const _gongjuLng = 127.1191;
const _nonsanLat = 36.2004;
const _nonsanLng = 127.0956;
const _buyeoLat = 36.2757;
const _buyeoLng = 126.9100;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _fmController = fm.MapController();
  Object? _kakaoController;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(mapSearchViewModelProvider.notifier).searchNearby(),
    );
  }

  void _moveToRegion(String region) {
    ref.read(mapSearchViewModelProvider.notifier).setRegion(region);
    final lat = region == 'NONSAN' ? _nonsanLat : region == 'BUYEO' ? _buyeoLat : _gongjuLat;
    final lng = region == 'NONSAN' ? _nonsanLng : region == 'BUYEO' ? _buyeoLng : _gongjuLng;
    if (kIsWeb) {
      _fmController.move(ll.LatLng(lat, lng), 11);
    } else {
      moveKakaoMap(_kakaoController, lat, lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapSearchViewModelProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? fm.FlutterMap(
                    mapController: _fmController,
                    options: const fm.MapOptions(
                      initialCenter: ll.LatLng(_gongjuLat, _gongjuLng),
                      initialZoom: 11,
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.skutechtour.routemaker',
                      ),
                      fm.MarkerLayer(
                        markers: state.places
                            .map((p) => fm.Marker(
                                  point: ll.LatLng(p.lat, p.lng),
                                  width: 36,
                                  height: 36,
                                  child: _PlaceMarker(type: p.type.name),
                                ))
                            .toList(),
                      ),
                    ],
                  )
                : buildKakaoMap(
                    state: state,
                    onCreated: (c) => setState(() => _kakaoController = c),
                  ),
          ),
          // 상단: 뒤로가기 + 검색바
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.chevron_left, size: 24, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 14),
                        Icon(Icons.search, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '현재 내 주변 10분 거리 콤보',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 지역 탭
          Positioned(
            top: topPad + 12 + 44 + 12,
            left: 16,
            right: 16,
            child: _RegionTabs(selected: state.region, onSelect: _moveToRegion),
          ),
          // 필터 하단시트
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FilterSheet(),
          ),
        ],
      ),
    );
  }
}

class _RegionTabs extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _RegionTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const regions = [('논산', 'NONSAN'), ('공주', 'GONGJU'), ('부여', 'BUYEO')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: regions.map((r) {
          final isSelected = selected == r.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(r.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(r.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapSearchViewModelProvider);
    final notifier = ref.read(mapSearchViewModelProvider.notifier);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Align(alignment: Alignment.centerLeft,
            child: Text('상황별 맞춤 필터',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          const SizedBox(height: 12),
          Row(children: [
            _FilterChip(label: '유모차 가능', icon: Icons.baby_changing_station, selected: state.strollerAccessible, onTap: () => notifier.toggleStrollerAccessible(!state.strollerAccessible)),
            const SizedBox(width: 8),
            _FilterChip(label: '반려동물', icon: Icons.pets, selected: state.petFriendly, onTap: () => notifier.togglePetFriendly(!state.petFriendly)),
            const SizedBox(width: 8),
            _FilterChip(label: '대형주차장', icon: Icons.local_parking, selected: state.parking, onTap: () => notifier.toggleParking(!state.parking)),
          ]),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.accent : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? Colors.white : Colors.black54),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12,
            color: selected ? Colors.white : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  final String type;
  const _PlaceMarker({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'restaurant' => (Icons.restaurant, Colors.orange),
      'cafe' => (Icons.local_cafe, const Color(0xFF8B5CF6)),
      _ => (Icons.museum, AppTheme.accent),
    };
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
