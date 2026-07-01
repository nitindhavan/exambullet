import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

enum AppButtonVariant { primary, secondary, outline }

/// The single button used across the app.
///
/// - [AppButtonVariant.primary]   → indigo gradient, white label (main CTA)
/// - [AppButtonVariant.secondary] → light indigo fill, indigo label
/// - [AppButtonVariant.outline]   → transparent, bordered, indigo label
class AppButton extends StatelessWidget {
  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.height = 54,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;
  final double height;

  Color get _foreground {
    if (variant == AppButtonVariant.primary) return Colors.white;
    return AppTheme.primary;
  }

  BoxDecoration _decoration(bool disabled) {
    switch (variant) {
      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: AppTheme.brMd,
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.brMd,
          border: Border.all(color: AppTheme.border, width: 1.5),
        );
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.brMd,
          boxShadow: disabled ? null : AppTheme.softShadow,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;
    final Color fg = _foreground;

    return Opacity(
      opacity: disabled && !loading ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: AppTheme.brMd,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: expand
                ? null
                : const EdgeInsets.symmetric(horizontal: AppTheme.space6),
            alignment: Alignment.center,
            decoration: _decoration(disabled),
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: fg,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 20),
                        const SizedBox(width: AppTheme.space3),
                      ],
                      Text(
                        label,
                        style: AppTheme.label.copyWith(color: fg),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
