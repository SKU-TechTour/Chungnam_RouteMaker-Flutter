import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_curation/models/course.dart';
import '../../home_curation/models/selected_route.dart';
import '../../my_history/repositories/stamp_local_repository.dart';

class JourneyProgress {
  const JourneyProgress({
    required this.route,
    required this.currentIndex,
    required this.completed,
  });

  final SelectedRoute route;
  final int currentIndex;
  final bool completed;

  CourseSpot? get currentSpot => completed || currentIndex >= route.spots.length
      ? null
      : route.spots[currentIndex];
}

class JourneyProgressNotifier extends StateNotifier<JourneyProgress?> {
  JourneyProgressNotifier(this._historyRepository) : super(null);

  final StampLocalRepository _historyRepository;

  void start(SelectedRoute route) {
    state = JourneyProgress(route: route, currentIndex: 0, completed: false);
  }

  Future<bool> completeCurrentStop() async {
    final progress = state;
    if (progress == null || progress.completed) return false;
    final nextIndex = progress.currentIndex + 1;
    if (nextIndex < progress.route.spots.length) {
      state = JourneyProgress(
        route: progress.route,
        currentIndex: nextIndex,
        completed: false,
      );
      return false;
    }
    await _historyRepository.completeRoute(progress.route);
    state = JourneyProgress(
      route: progress.route,
      currentIndex: progress.route.spots.length,
      completed: true,
    );
    return true;
  }

  void clear() => state = null;
}
