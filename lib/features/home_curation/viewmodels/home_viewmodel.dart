import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';

enum HomeState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final _repository = CourseRepository();

  HomeState _state = HomeState.idle;
  Region _selectedRegion = Region.gongju;
  List<CourseModel> _courses = [];
  bool _isPlanB = false;
  String? _errorMessage;

  HomeState get state => _state;
  Region get selectedRegion => _selectedRegion;
  List<CourseModel> get courses => _courses;
  bool get isPlanB => _isPlanB;
  String? get errorMessage => _errorMessage;

  Future<void> loadCourses() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      _courses = await _repository.getCourses(_selectedRegion);
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeState.error;
    }
    notifyListeners();
  }

  Future<void> shufflePlanB() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      _courses = await _repository.getPlanBCourses(_selectedRegion);
      _isPlanB = true;
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeState.error;
    }
    notifyListeners();
  }

  void selectRegion(Region region) {
    _selectedRegion = region;
    _isPlanB = false;
    notifyListeners();
    loadCourses();
  }
}
