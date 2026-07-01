import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

/// Standard surface card: white fill, light border, soft shadow, [radiusLg].
///
/// Use for every "panel" in the app so padding, radius, border and elevation
/// stay uniform. Pass [onTap] to make it tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space5),
    this.margin,
    this.onTap,
    this.highlighted = false,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// When true, uses the indigo accent border instead of the neutral one.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.brLg,
      border: Border.all(
        color: highlighted
            ? AppTheme.primary.withValues(alpha: 0.3)
            : AppTheme.borderLight,
        width: highlighted ? 1.5 : 1,
      ),
      boxShadow: AppTheme.softShadow,
    );

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.brLg,
          child: content,
        ),
      ),
    );
  }
}
