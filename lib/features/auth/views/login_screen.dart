import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/route_maker_logo.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    if (await action() && context.mounted) context.go('/preferences');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 30, 28, 0),
                  child: RouteMakerLogo(light: true),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    '이번 주말,\n어디로 걸어볼까요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.22,
                      letterSpacing: -1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    '논산 · 공주 · 부여의 숨은 순간을\n당신만의 루트로 만들어드릴게요.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 38),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: viewModel.state == AuthState.loading
                      ? const SizedBox(
                          height: 190,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '3초 만에 여행을 시작해요',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SocialButton(
                              label: 'Google로 계속하기',
                              icon: Image.asset(
                                'assets/images/auth/google_logo.png',
                                width: 20,
                                height: 20,
                              ),
                              onTap: () =>
                                  _signIn(context, viewModel.loginWithGoogle),
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () =>
                                  _signIn(context, viewModel.continueAsGuest),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                              ),
                              label: const Text('로그인 없이 둘러보기'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                            if (viewModel.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  viewModel.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 2),
                            const Text(
                              '계속하면 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
