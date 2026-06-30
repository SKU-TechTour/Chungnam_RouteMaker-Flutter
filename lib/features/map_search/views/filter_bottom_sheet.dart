import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';

/// [SB 화면 3] 반려동물/유모차 필터 바텀시트.
class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapSearchViewModelProvider);
    final notifier = ref.read(mapSearchViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('동반자 필터', style: Theme.of(context).textTheme.titleLarge),
          CheckboxListTile(
            title: const Text('반려동물 동반 가능'),
            value: state.petFriendly,
            onChanged: (v) => notifier.togglePetFriendly(v ?? false),
          ),
          CheckboxListTile(
            title: const Text('유모차 접근 가능'),
            value: state.strollerAccessible,
            onChanged: (v) => notifier.toggleStrollerAccessible(v ?? false),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.searchNearby();
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }
}
