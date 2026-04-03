import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF9FCFF),
            AppColors.background,
            Color(0xFFE8F2FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -70,
            child: _GlowBubble(
              size: 280,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 110,
            left: -80,
            child: _GlowBubble(
              size: 210,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -20,
            child: _GlowBubble(
              size: 230,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -70,
            child: _GlowBubble(
              size: 150,
              color: AppColors.accent.withValues(alpha: 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
