import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/providers.dart';
import '../models/saved_course.dart';
import '../repositories/course_bookmark_repository.dart';

final courseBookmarkRepositoryProvider = Provider(
  (ref) => CourseBookmarkRepository(ref.watch(dioProvider)),
);

final popularCoursesProvider = FutureProvider<List<SavedCourse>>(
  (ref) => ref.watch(courseBookmarkRepositoryProvider).fetchPopular(limit: 10),
);

final savedCoursesProvider =
    StateNotifierProvider<SavedCoursesNotifier, List<SavedCourse>>(
      (ref) => SavedCoursesNotifier(
        ref,
        ref.watch(courseBookmarkRepositoryProvider),
      ),
    );

class SavedCoursesNotifier extends StateNotifier<List<SavedCourse>> {
  SavedCoursesNotifier(this._ref, this._remote) : super(const []) {
    unawaited(_load());
  }

  final Ref _ref;
  final CourseBookmarkRepository _remote;

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
    final index = state.indexWhere((item) => item.routeKey == course.routeKey);
    if (index < 0) {
      state = [...state, course];
      unawaited(_save());
      unawaited(_sync(() => _remote.save(course)));
      return;
    }
    if (state[index].hasSameRoute(course)) {
      final removed = state[index];
      state = state.where((item) => item.routeKey != course.routeKey).toList();
      unawaited(_save());
      unawaited(_sync(() => _remote.remove(removed)));
      return;
    }
    final updated = [...state];
    updated[index] = course;
    state = updated;
    unawaited(_save());
    unawaited(_sync(() => _remote.save(course)));
  }

  void remove(String id) {
    _changedBeforeLoad = true;
    final removed = state.where((course) => course.id == id).firstOrNull;
    state = state.where((course) => course.id != id).toList();
    unawaited(_save());
    if (removed != null) unawaited(_sync(() => _remote.remove(removed)));
  }

  void reset() {
    _changedBeforeLoad = true;
    state = const [];
  }

  Future<void> _sync(Future<void> Function() request) async {
    try {
      await request();
      _ref.invalidate(popularCoursesProvider);
    } catch (_) {
      // 로컬 찜은 네트워크와 무관하게 유지하고 다음 사용자 동작 때 재동기화한다.
    }
  }
}
