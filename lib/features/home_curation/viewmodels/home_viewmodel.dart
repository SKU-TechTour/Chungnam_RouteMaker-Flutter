import 'package:flutter/material.dart';
import 'package:flutterprojects/core/network/dio_client.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

enum HomeState { idle, loading, success, error }

enum Region { nonsan, gongju, buyeo }

class HomeViewModel extends ChangeNotifier {
  final _repository = CourseRepository(DioClient.instance.dio);

  HomeState _state = HomeState.idle;
  Region _selectedRegion = Region.gongju;
  List<Course> _courses = [];
  bool _isPlanB = false;
  String? _errorMessage;

  HomeState get state => _state;
  Region get selectedRegion => _selectedRegion;
  List<Course> get courses => _courses;
  bool get isPlanB => _isPlanB;
  String? get errorMessage => _errorMessage;

  Future<void> loadCourses() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      _courses = await _repository.fetchCourses(
        region: _selectedRegion.name.toUpperCase(),
      );
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
      if (_courses.isEmpty) {
        await loadCourses();
        return;
      }
      _courses = [await _repository.shufflePlanB(_courses.first.id)];
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
