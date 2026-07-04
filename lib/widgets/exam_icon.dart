import 'package:flutter/material.dart';
import 'package:percent/utils/category_icons.dart';
import 'package:percent/utils/theme.dart';

/// Renders an exam's icon with priority: a named icon ([iconKey]) wins over an
/// uploaded [imageUrl]; if neither is usable, a generic school icon is shown.
///
/// Use this everywhere an exam icon appears so the image-or-named-icon behaviour
/// stays consistent across the app.
class ExamIcon extends StatelessWidget {
  const ExamIcon({
    Key? key,
    required this.iconKey,
    required this.imageUrl,
    this.size = 24,
    this.color = AppTheme.primary,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  final String iconKey;
  final String imageUrl;
  final double size;
  final Color color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (iconKey.isNotEmpty && kCategoryIcons.containsKey(iconKey)) {
      return Icon(kCategoryIcons[iconKey], size: size, color: color);
    }
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.school_rounded, size: size, color: color),
      );
    }
    return Icon(Icons.school_rounded, size: size, color: color);
  }
}
