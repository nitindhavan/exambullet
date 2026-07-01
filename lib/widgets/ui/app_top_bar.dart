import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

/// The single Material app bar used across light screens (Notifications,
/// Edit Profile, Privacy, Test, Verify, …).
///
/// Light [background] fill, no shadow, a back chevron in [textPrimary] and a
/// left-aligned [headingMd] title. Drops straight into `Scaffold.appBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.leadingIcon,
  }) : super(key: key);

  final String title;
  final List<Widget>? actions;

  /// Defaults to `Navigator.pop`. Ignored when [showBack] is false.
  final VoidCallback? onBack;
  final bool showBack;

  /// Optional icon shown before the title (e.g. the app logo on Home).
  final IconData? leadingIcon;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      surfaceTintColor: AppTheme.background,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Snug against the back chevron when present; otherwise use a slightly
      // wider left gutter so the title isn't flush against the screen edge.
      titleSpacing: showBack ? 0 : AppTheme.space6,
      systemOverlayStyle: AppTheme.lightSurface,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: leadingIcon == null
          ? Text(title, style: AppTheme.headingMd)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppTheme.brSm,
                  ),
                  child: Icon(leadingIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppTheme.space3),
                Text(title, style: AppTheme.headingMd),
              ],
            ),
      actions: actions,
    );
  }
}
