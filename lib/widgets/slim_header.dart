import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';

/// Slim, clean in-body header (white surface, dark back arrow, eyebrow + title,
/// subtle bottom border). Shared so the subject path and content screens match.
class SlimHeader extends StatelessWidget {
  const SlimHeader({
    Key? key,
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.trailing,
  }) : super(key: key);

  final String eyebrow;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textPrimary, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(eyebrow,
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
