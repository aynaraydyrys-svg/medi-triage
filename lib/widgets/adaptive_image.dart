import 'dart:convert';

import 'package:flutter/material.dart';

class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      final uri = Uri.tryParse(imageUrl);
      final data = uri?.data;
      if (data != null) {
        return Image.memory(
          data.contentAsBytes(),
          fit: fit,
          width: width,
          height: height,
        );
      }

      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex != -1) {
        final raw = imageUrl.substring(commaIndex + 1);
        return Image.memory(
          base64Decode(raw),
          fit: fit,
          width: width,
          height: height,
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Color(0xFFEAF3FF));
      },
    );
  }
}
