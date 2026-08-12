import 'package:flutterprojects/features/auth/models/user_model.dart';

class AuthRepository {
  Future<UserModel> loginWithGoogle() async {
    // TODO: Firebase 설정 후 실제 Google OAuth 연동
    await Future.delayed(const Duration(milliseconds: 800));
    return const UserModel(
      id: 'mock-001',
      name: '홍길동',
      email: 'test@routemaker.com',
    );
  }

  Future<UserModel> loginWithKakao() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const UserModel(
      id: 'mock-002',
      name: '카카오유저',
      email: 'kakao@routemaker.com',
    );
  }

  Future<UserModel> continueAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const UserModel(
      id: 'guest',
      name: '여행자',
      email: 'guest@routemaker.local',
    );
  }

  Future<UserModel> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const UserModel(
      id: 'mock-003',
      name: 'Apple User',
      email: 'apple@routemaker.com',
    );
  }

  Future<void> logout() async {}
}
