import 'package:flutter/material.dart';
import '../models/place_filter_model.dart';
import '../repositories/map_repository.dart';

enum MapState { idle, loading, success, error }

class MapViewModel extends ChangeNotifier {
  final _repository = MapRepository();

  MapState _state = MapState.idle;
  PlaceFilterModel _filter = const PlaceFilterModel();
  List<MapPlaceModel> _places = [];
  String? _errorMessage;

  MapState get state => _state;
  PlaceFilterModel get filter => _filter;
  List<MapPlaceModel> get places => _places;
  String? get errorMessage => _errorMessage;

  Future<void> search() async {
    _state = MapState.loading;
    notifyListeners();

    try {
      _places = await _repository.filterPlaces(_filter);
      _state = MapState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = MapState.error;
    }
    notifyListeners();
  }

  void toggleStroller() {
    _filter = _filter.copyWith(stroller: !_filter.stroller);
    notifyListeners();
    search();
  }

  void togglePet() {
    _filter = _filter.copyWith(pet: !_filter.pet);
    notifyListeners();
    search();
  }

  void toggleParking() {
    _filter = _filter.copyWith(parking: !_filter.parking);
    notifyListeners();
    search();
  }

  void setRegion(String region) {
    _filter = _filter.copyWith(region: region);
    notifyListeners();
    search();
  }
}
