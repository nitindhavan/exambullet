import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

/// A small pill that flips a translated question between its translation and the
/// original English. [showingOriginal] reflects the current state; [onTap]
/// toggles it. Shown only on a translated attempt.
class OriginalToggle extends StatelessWidget {
  const OriginalToggle({
    Key? key,
    required this.showingOriginal,
    required this.onTap,
  }) : super(key: key);

  final bool showingOriginal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: showingOriginal ? AppTheme.primary : AppTheme.primaryLight,
          borderRadius: AppTheme.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded,
                size: 14,
                color: showingOriginal ? Colors.white : AppTheme.primary),
            const SizedBox(width: 5),
            Text(
              showingOriginal ? 'Original' : 'Show original',
              style: AppTheme.label.copyWith(
                fontSize: 11,
                color: showingOriginal ? Colors.white : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
