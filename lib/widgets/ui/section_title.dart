import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

/// A section heading with an optional trailing action (e.g. "Manage", "View All").
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    Key? key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
        AppTheme.space6, AppTheme.space4, AppTheme.space6, AppTheme.space4),
  }) : super(key: key);

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.headingMd),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTheme.label.copyWith(
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
