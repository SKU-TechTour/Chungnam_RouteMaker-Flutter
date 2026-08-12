import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/route_maker_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    context.go(
      preferences.getBool('onboarded') ?? false ? '/login' : '/onboarding',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -80,
            child: _Glow(size: 280, color: AppTheme.accent),
          ),
          const Positioned(
            bottom: -120,
            left: -100,
            child: _Glow(size: 300, color: AppTheme.coral),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Center(child: RouteMakerLogo(light: true)),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 48,
            child: Text(
              '나만의 속도로 떠나는 충남 여행',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.17),
      shape: BoxShape.circle,
    ),
  );
}
