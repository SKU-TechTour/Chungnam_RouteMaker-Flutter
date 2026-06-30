import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/map_search/views/filter_bottom_sheet.dart';

/// [SB 화면 3] 지도 GPS 매핑 및 동반자 필터 화면.
///
/// 실제 지도 SDK(google_maps_flutter 등) 연동은 이 화면에서 확장합니다.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapSearchViewModelProvider);
    final notifier = ref.read(mapSearchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도 검색'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const FilterBottomSheet(),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.places.length,
              itemBuilder: (context, index) {
                final place = state.places[index];
                return ListTile(
                  title: Text(place.name),
                  subtitle: Text(
                    '${place.type.name} · ${place.lat.toStringAsFixed(4)}, '
                    '${place.lng.toStringAsFixed(4)}',
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.searchNearby,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
