import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place.dart';

final savedPlacesProvider =
    StateNotifierProvider<SavedPlacesNotifier, List<SavedPlace>>(
      (ref) => SavedPlacesNotifier(),
    );

class SavedPlacesNotifier extends StateNotifier<List<SavedPlace>> {
  SavedPlacesNotifier() : super(const []) {
    unawaited(_load());
  }

  static const _storageKey = 'saved_places';
  bool _changedBeforeLoad = false;

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const [];
    if (_changedBeforeLoad) return;
    state = raw
        .map(
          (item) =>
              SavedPlace.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  bool contains(SavedPlace place) =>
      state.any((item) => item.storageKey == place.storageKey);

  void toggle(SavedPlace place) {
    _changedBeforeLoad = true;
    if (contains(place)) {
      state = state
          .where((item) => item.storageKey != place.storageKey)
          .toList(growable: false);
    } else {
      state = [...state, place];
    }
    unawaited(_save());
  }

  void remove(SavedPlace place) {
    _changedBeforeLoad = true;
    state = state
        .where((item) => item.storageKey != place.storageKey)
        .toList(growable: false);
    unawaited(_save());
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      state.map((place) => jsonEncode(place.toJson())).toList(growable: false),
    );
  }
}
