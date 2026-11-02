import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/services/language_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/start_test_language_sheet.dart';

/// A slim bar above the Theory notes letting the reader translate them into a
/// language. Selection is per-topic (not global). Tapping opens the shared
/// language sheet (which downloads the pack if needed). Shows a "reset to
/// original" chip once translated.
class NotesLanguageBar extends StatelessWidget {
  const NotesLanguageBar({
    Key? key,
    required this.current,
    required this.onChanged,
  }) : super(key: key);

  /// Current BCP-47 code ('en' = original).
  final String current;
  final ValueChanged<String> onChanged;

  String get _label => LanguageService.supported
      .firstWhere((l) => l.code == current,
          orElse: () => LanguageService.supported.first)
      .label;

  Future<void> _open(BuildContext context) async {
    // Reuse the test language sheet — it handles model download + English lock.
    final code = await showStartTestLanguageSheet(
      context,
      paperName: 'these notes',
    );
    if (code != null) onChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = current == LanguageService.sourceLang;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space5, AppTheme.space3, AppTheme.space5, AppTheme.space3),
      color: AppTheme.background,
      child: Row(
        children: [
          const Icon(Icons.translate_rounded,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnglish ? 'Read in your language' : 'Showing: $_label',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isEnglish) ...[
            _Chip(
              label: 'Original',
              filled: false,
              onTap: () => onChanged(LanguageService.sourceLang),
            ),
            const SizedBox(width: 8),
          ],
          _Chip(
            label: isEnglish ? 'Translate' : 'Change',
            filled: true,
            onTap: () => _open(context),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: filled ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
