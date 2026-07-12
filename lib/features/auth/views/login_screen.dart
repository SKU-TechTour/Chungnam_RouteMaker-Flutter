import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/features/auth/viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                '충남 루트메이커',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '논산 · 공주 · 부여\n나만의 여행 코스를 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 15, height: 1.6),
              ),
              const Spacer(flex: 2),
              if (vm.state == AuthState.loading)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                _KakaoButton(
                  onTap: () async {
                    final ok = await vm.loginWithKakao();
                    if (ok && context.mounted) context.go('/home');
                  },
                ),
                const SizedBox(height: 10),
                _GoogleButton(
                  onTap: () async {
                    final ok = await vm.loginWithGoogle();
                    if (ok && context.mounted) context.go('/home');
                  },
                ),
                const SizedBox(height: 10),
                _AppleButton(
                  onTap: () async {
                    final ok = await vm.loginWithGoogle();
                    if (ok && context.mounted) context.go('/home');
                  },
                ),
              ],
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(vm.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _KakaoButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFFEE500), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: Center(
        child: Image.asset(
          'assets/images/auth/kakao_btn.png',
          height: 46,
          fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) => const Text('카카오 로그인', style: TextStyle(color: Color(0xFF3C1E1E), fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  );
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/auth/google_logo.png', width: 22, height: 22,
            errorBuilder: (_, __, ___) => const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 20, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          const Text('Google로 계속하기', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        ],
      ),
    ),
  );
}

class _AppleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AppleButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apple, color: Colors.white, size: 26),
          SizedBox(width: 6),
          Text('Apple로 계속하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
        ],
      ),
    ),
  );
}
