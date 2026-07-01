import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent/utils/theme.dart';

/// The canonical indigo gradient header used at the top of detail screens
/// (score, result, dashboard, membership, …).
///
/// Handles the status-bar padding and sets the dark-surface overlay style so
/// status icons stay light. Provide a [title], optional [subtitle], an optional
/// [onBack] (renders a back chevron) and optional [trailing]/[bottom] widgets.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
  }) : super(key: key);

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Extra content rendered below the title row (e.g. a progress bar or tabs).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkSurface,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppTheme.space5,
          topPad + AppTheme.space4,
          AppTheme.space5,
          AppTheme.space7,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radiusHeader),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onBack != null) ...[
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack!,
                  ),
                  const SizedBox(width: AppTheme.space3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.displayLg.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.space3),
                  trailing!,
                ],
              ],
            ),
            if (bottom != null) ...[
              const SizedBox(height: AppTheme.space5),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
