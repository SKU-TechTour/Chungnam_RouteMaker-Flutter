import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_course.dart';

final savedCoursesProvider =
    StateNotifierProvider<SavedCoursesNotifier, List<SavedCourse>>(
      (ref) => SavedCoursesNotifier(),
    );

class SavedCoursesNotifier extends StateNotifier<List<SavedCourse>> {
  SavedCoursesNotifier() : super(const []) {
    unawaited(_load());
  }

  static const _storageKey = 'saved_courses';
  bool _changedBeforeLoad = false;

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const [];
    if (_changedBeforeLoad) return;
    state = raw
        .map(
          (item) =>
              SavedCourse.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      state.map((course) => jsonEncode(course.toJson())).toList(),
    );
  }

  bool contains(String id) => state.any((course) => course.id == id);

  void toggle(SavedCourse course) {
    _changedBeforeLoad = true;
    final index = state.indexWhere((item) => item.id == course.id);
    if (index < 0) {
      state = [...state, course];
      unawaited(_save());
      return;
    }
    if (state[index].hasSameRoute(course)) {
      state = state.where((item) => item.id != course.id).toList();
      unawaited(_save());
      return;
    }
    final updated = [...state];
    updated[index] = course;
    state = updated;
    unawaited(_save());
  }

  void remove(String id) {
    _changedBeforeLoad = true;
    state = state.where((course) => course.id != id).toList();
    unawaited(_save());
  }

  void reset() {
    _changedBeforeLoad = true;
    state = const [];
  }
}
