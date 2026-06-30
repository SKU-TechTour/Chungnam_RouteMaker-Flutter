import 'package:flutterprojects/features/home_curation/models/course.dart';

/// [SB 화면 1] 홈 큐레이션 View 상태.
class HomeCurationState {
  const HomeCurationState({
    this.courses = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Course> courses;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;

  Course? get currentCourse =>
      courses.isEmpty ? null : courses[currentIndex % courses.length];

  HomeCurationState copyWith({
    List<Course>? courses,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeCurationState(
      courses: courses ?? this.courses,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
