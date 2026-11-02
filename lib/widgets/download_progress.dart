import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';

/// A download indicator for language packs.
///
/// ML Kit's Flutter API does not expose real byte-level progress (its
/// downloadModel just returns a done/failed Future), so this shows an honest
/// animated "filling" bar that eases toward — but never reaches — 100% while the
/// download runs. The caller flips it to complete when the Future resolves.
///
/// Drive it by rebuilding with [done] = true on completion; the bar snaps to
/// 100% then. While running, keep [done] = false.
class DownloadProgress extends StatefulWidget {
  const DownloadProgress({
    Key? key,
    required this.label,
    this.done = false,
  }) : super(key: key);

  /// e.g. "Downloading हिन्दी pack (~30 MB)".
  final String label;

  /// True once the underlying download Future has resolved successfully.
  final bool done;

  @override
  State<DownloadProgress> createState() => _DownloadProgressState();
}

class _DownloadProgressState extends State<DownloadProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    // ~model download feel: ease from 0 to ~92% over this window, then hold.
    duration: const Duration(seconds: 18),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Curve eases toward 0.92 while running; snap to 1.0 when done.
        final raw = Curves.easeOut.transform(_ctrl.value);
        final pct = widget.done ? 1.0 : (raw * 0.92);
        final display = (pct * 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.done ? 'Downloaded' : widget.label,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
                Text('$display%',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: AppTheme.borderLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
