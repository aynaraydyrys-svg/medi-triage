import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'adaptive_image.dart';

class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 28,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ColoredBox(
          color: AppColors.backgroundAlt,
          child: hasImage
              ? AdaptiveImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                )
              : Center(
                  child: Text(
                    initials.isEmpty ? 'MM' : initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: radius * 0.45,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
