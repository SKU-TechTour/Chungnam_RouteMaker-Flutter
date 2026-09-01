import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutterprojects/features/auth/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;

  Future<UserModel> loginWithGoogle() async {
    final firebase_auth.UserCredential credential;

    if (kIsWeb) {
      credential = await _firebaseAuth.signInWithPopup(
        firebase_auth.GoogleAuthProvider(),
      );
    } else {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final firebaseCredential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      credential = await _firebaseAuth.signInWithCredential(firebaseCredential);
    }

    return _toUserModel(credential.user);
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
    final credential = await _firebaseAuth.signInAnonymously();
    return _toUserModel(credential.user);
  }

  Future<UserModel> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const UserModel(
      id: 'mock-003',
      name: 'Apple User',
      email: 'apple@routemaker.com',
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  UserModel _toUserModel(firebase_auth.User? user) {
    if (user == null) {
      throw StateError('Firebase 로그인 결과에 사용자 정보가 없습니다.');
    }

    return UserModel(
      id: user.uid,
      name: user.displayName ?? (user.isAnonymous ? '여행자' : '사용자'),
      email: user.email ?? '',
      profileImage: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }
}
