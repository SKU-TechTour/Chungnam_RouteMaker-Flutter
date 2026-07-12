import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final _repository = AuthRepository();

  AuthState _state = AuthState.idle;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<bool> loginWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.loginWithGoogle();
      _state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithKakao() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.loginWithKakao();
      _state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _state = AuthState.idle;
    notifyListeners();
  }
}
