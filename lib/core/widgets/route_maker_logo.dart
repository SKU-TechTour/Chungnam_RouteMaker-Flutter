import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RouteMakerLogo extends StatelessWidget {
  const RouteMakerLogo({super.key, this.light = false, this.compact = false});

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppTheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 52,
          height: compact ? 36 : 52,
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: 0.14)
                : AppTheme.primary,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.route_rounded,
                color: light ? Colors.white : AppTheme.softMint,
                size: compact ? 22 : 30,
              ),
              Positioned(
                right: compact ? 6 : 9,
                top: compact ? 6 : 9,
                child: Container(
                  width: compact ? 6 : 8,
                  height: compact ? 6 : 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.coral,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUTE MAKER',
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '충남 여행 큐레이터',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
