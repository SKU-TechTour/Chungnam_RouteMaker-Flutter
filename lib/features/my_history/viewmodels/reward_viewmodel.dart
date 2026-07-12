import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../repositories/reward_repository.dart';

enum RewardState { idle, loading, success, error }

class RewardViewModel extends ChangeNotifier {
  final _repository = RewardRepository();

  RewardState _state = RewardState.idle;
  RewardModel? _reward;
  bool _isSharing = false;
  String? _errorMessage;

  RewardState get state => _state;
  RewardModel? get reward => _reward;
  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = RewardState.loading;
    notifyListeners();

    try {
      _reward = await _repository.getRewards();
      _state = RewardState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = RewardState.error;
    }
    notifyListeners();
  }

  Future<String?> shareCard(String courseId) async {
    _isSharing = true;
    notifyListeners();

    try {
      final url = await _repository.generateShareCard(courseId);
      _isSharing = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isSharing = false;
      notifyListeners();
      return null;
    }
  }
}
