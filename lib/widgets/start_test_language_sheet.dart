import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/services/language_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/download_progress.dart';

/// Bottom sheet shown when a user taps a question paper: "Start this paper in —
/// English / हिन्दी / …". Returns the chosen BCP-47 code (e.g. 'en', 'hi') to
/// start the attempt in, or null if dismissed.
///
/// If [subjectHint] looks like an English-language subject (grammar, vocab,
/// comprehension — where translating would destroy the question), the sheet
/// locks to English and explains why.
///
/// Selecting a not-yet-downloaded language downloads its ~30 MB model first.
Future<String?> showStartTestLanguageSheet(
  BuildContext context, {
  required String paperName,
  String subjectHint = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StartTestLanguageSheet(
      paperName: paperName,
      englishOnly: LanguageService.isEnglishSubject(subjectHint) ||
          LanguageService.isEnglishSubject(paperName),
    ),
  );
}

class _StartTestLanguageSheet extends StatefulWidget {
  const _StartTestLanguageSheet({
    required this.paperName,
    required this.englishOnly,
  });

  final String paperName;
  final bool englishOnly;

  @override
  State<_StartTestLanguageSheet> createState() =>
      _StartTestLanguageSheetState();
}

class _StartTestLanguageSheetState extends State<_StartTestLanguageSheet> {
  String? _downloading;
  final Set<String> _downloaded = {};

  @override
  void initState() {
    super.initState();
    if (!widget.englishOnly) _refreshDownloaded();
  }

  Future<void> _refreshDownloaded() async {
    final svc = LanguageService.instance;
    final present = <String>{};
    for (final l in LanguageService.supported) {
      if (await svc.isModelDownloaded(l.code)) present.add(l.code);
    }
    if (mounted) setState(() => _downloaded.addAll(present));
  }

  String _downloadingLabel() {
    final code = _downloading;
    if (code == null) return '';
    return LanguageService.supported
        .firstWhere((l) => l.code == code,
            orElse: () => const LanguageOption('', ''))
        .label;
  }

  Future<void> _pick(LanguageOption lang) async {
    final svc = LanguageService.instance;
    if (lang.code == LanguageService.sourceLang ||
        await svc.isModelDownloaded(lang.code)) {
      if (mounted) Navigator.pop(context, lang.code);
      return;
    }
    setState(() => _downloading = lang.code);
    final ok = await svc.downloadModel(lang.code);
    if (!mounted) return;
    setState(() => _downloading = null);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not download ${lang.label}. Try again.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    _downloaded.add(lang.code);
    if (mounted) Navigator.pop(context, lang.code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Start test',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 3),
          Text(widget.paperName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),

          if (widget.englishOnly) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppTheme.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is an English-language paper, so it can only be '
                      'taken in English — translating it would change the '
                      'questions.',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppTheme.textPrimary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, LanguageService.sourceLang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Start in English',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ] else if (_downloading != null) ...[
            // A pack is downloading — show progress instead of the list.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: DownloadProgress(
                label: 'Downloading ${_downloadingLabel()} pack (~30 MB)',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This one-time download lets you take tests in this language '
              'fully offline.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ] else ...[
            Text('Take this test in',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: LanguageService.supported.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final lang = LanguageService.supported[i];
                  final isEnglish = lang.code == LanguageService.sourceLang;
                  final downloaded =
                      isEnglish || _downloaded.contains(lang.code);
                  return _Row(
                    label: lang.label,
                    downloading: false,
                    downloaded: downloaded,
                    isEnglish: isEnglish,
                    onTap: () => _pick(lang),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.downloading,
    required this.downloaded,
    required this.isEnglish,
    required this.onTap,
  });

  final String label;
  final bool downloading, downloaded, isEnglish;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ),
              if (downloading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary),
                )
              else if (isEnglish)
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textLight, size: 22)
              else if (downloaded)
                Icon(Icons.offline_pin_rounded,
                    color: AppTheme.success.withValues(alpha: 0.8), size: 20)
              else
                const Icon(Icons.download_rounded,
                    color: AppTheme.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
