import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a study note written in Markdown, with raw `<svg>…</svg>` blocks
/// rendered as real diagrams.
///
/// The note is presented as a stack of "section cards": each `##` heading
/// starts a new card, so a long note reads as digestible chunks rather than one
/// unbroken wall of text. Generated notes number their headings ("## 1. What it
/// is…"); the number is pulled out into a badge instead of sitting in the text.
///
/// flutter_markdown treats raw HTML as plain text, so rather than fight it we
/// split each section on `<svg>` blocks and render prose and diagrams with the
/// right widget.
class NotesMarkdown extends StatelessWidget {
  const NotesMarkdown({
    Key? key,
    required this.data,
    this.padding,
    this.maxSections,
    this.onUnlock,
  }) : super(key: key);

  final String data;
  final EdgeInsetsGeometry? padding;

  /// When set, only the first N sections render and a paywall card is appended
  /// (used to give non-members a preview of the notes).
  final int? maxSections;

  /// Tapping the paywall card. Required for [maxSections] to show one.
  final VoidCallback? onUnlock;

  static final RegExp _svgBlock =
      RegExp(r'<svg[\s\S]*?<\/svg>', caseSensitive: false);

  /// `## 3. Core concept` → captures ("3", "Core concept"). The number is
  /// optional, so plain `## Heading` works too.
  static final RegExp _h2 =
      RegExp(r'^##\s+(?:(\d+)[.)]\s*)?(.+)$', multiLine: true);

  @override
  Widget build(BuildContext context) {
    final all = _sections(data);

    // Preview mode: cut to maxSections and append a paywall card.
    final limit = maxSections;
    final gated = limit != null && onUnlock != null && all.length > limit;
    final sections = gated ? all.take(limit).toList() : all;
    final hiddenCount = gated ? all.length - limit : 0;

    return ListView.builder(
      padding: padding ??
          const EdgeInsets.fromLTRB(AppTheme.space5, AppTheme.space5,
              AppTheme.space5, AppTheme.space8),
      itemCount: sections.length + (gated ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= sections.length) {
          return _PaywallCard(hiddenCount: hiddenCount, onUnlock: onUnlock!);
        }
        return _SectionCard(section: sections[i]);
      },
    );
  }

  /// Splits the note into sections at each `##` heading. Anything before the
  /// first `##` (usually the `# Title` + subtitle line) becomes an intro
  /// section with no header — the screen already shows the topic name.
  static List<_Section> _sections(String source) {
    final matches = _h2.allMatches(source).toList();

    if (matches.isEmpty) {
      final body = _stripLeadingTitle(source).trim();
      return body.isEmpty
          ? const []
          : [_Section(number: null, title: null, body: body)];
    }

    final out = <_Section>[];

    final intro = _stripLeadingTitle(source.substring(0, matches.first.start)).trim();
    if (intro.isNotEmpty) {
      out.add(_Section(number: null, title: null, body: intro));
    }

    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final end = i + 1 < matches.length ? matches[i + 1].start : source.length;
      out.add(_Section(
        number: m.group(1),
        title: (m.group(2) ?? '').trim(),
        body: source.substring(m.end, end).trim(),
      ));
    }
    return out;
  }

  /// Drops a leading `# Title` and the `*Exam · Subject*` byline under it —
  /// both duplicate what the topic screen's header already shows.
  static String _stripLeadingTitle(String s) {
    var out = s.replaceFirst(RegExp(r'^\s*#\s+[^\n]*\n?'), '');
    out = out.replaceFirst(RegExp(r'^\s*\*[^*\n]*·[^*\n]*\*\s*\n?'), '');
    return out;
  }

  static List<_Segment> _splitSvg(String source) {
    final out = <_Segment>[];
    var last = 0;
    for (final m in _svgBlock.allMatches(source)) {
      if (m.start > last) {
        final md = source.substring(last, m.start).trim();
        if (md.isNotEmpty) out.add(_Segment(md, false));
      }
      out.add(_Segment(m.group(0)!, true));
      last = m.end;
    }
    if (last < source.length) {
      final md = source.substring(last).trim();
      if (md.isNotEmpty) out.add(_Segment(md, false));
    }
    if (out.isEmpty && source.trim().isNotEmpty) {
      out.add(_Segment(source.trim(), false));
    }
    return out;
  }
}

/// One `##` section, rendered as a card with a numbered header.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _Section section;

  /// Accent per section type, so formulas/tips/examples are visually distinct.
  Color get _accent {
    final t = (section.title ?? '').toLowerCase();
    if (t.contains('formula') || t.contains('rule')) return AppTheme.warning;
    if (t.contains('tip') || t.contains('trap') || t.contains('mistake')) {
      return AppTheme.error;
    }
    if (t.contains('example') || t.contains('solved') || t.contains('worked')) {
      return AppTheme.success;
    }
    if (t.contains('diagram') || t.contains('visual')) return AppTheme.secondary;
    return AppTheme.primary;
  }

  IconData get _icon {
    final t = (section.title ?? '').toLowerCase();
    if (t.contains('formula') || t.contains('rule')) return Icons.functions_rounded;
    if (t.contains('tip') || t.contains('trap') || t.contains('mistake')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (t.contains('example') || t.contains('solved') || t.contains('worked')) {
      return Icons.check_circle_outline_rounded;
    }
    if (t.contains('diagram') || t.contains('visual')) {
      return Icons.account_tree_outlined;
    }
    if (t.contains('what it is') || t.contains('why')) {
      return Icons.info_outline_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final segments = NotesMarkdown._splitSvg(section.body);
    final hasHeader = section.title != null && section.title!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: _accent.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: section.number != null
                        ? Text(
                            section.number!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _accent,
                            ),
                          )
                        : Icon(_icon, size: 16, color: _accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.title!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, hasHeader ? 12 : 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final seg in segments)
                  seg.isSvg
                      ? _Diagram(svg: seg.text)
                      : _Prose(data: seg.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Markdown prose. Tables are split out and wrapped in a horizontal scroller —
/// the generated notes use 3-4 column formula tables that would otherwise
/// overflow the screen width on a phone.
class _Prose extends StatelessWidget {
  const _Prose({required this.data});
  final String data;

  /// A run of consecutive lines that all look like `| … | … |` table rows.
  static final RegExp _tableBlock =
      RegExp(r'(?:^[ \t]*\|.*\|[ \t]*$\n?){2,}', multiLine: true);

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    var last = 0;

    void addMarkdown(String md) {
      final t = md.trim();
      if (t.isEmpty) return;
      parts.add(_body(t));
    }

    for (final m in _tableBlock.allMatches(data)) {
      addMarkdown(data.substring(last, m.start));
      parts.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _body(m.group(0)!.trim()),
          ),
        ),
      );
      last = m.end;
    }
    addMarkdown(data.substring(last));

    if (parts.isEmpty) return const SizedBox.shrink();
    if (parts.length == 1) return parts.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget _body(String md) => MarkdownBody(
        data: md,
        selectable: true,
        onTapLink: (text, href, title) => _launch(href),
        styleSheet: _styleSheet(),
      );

  Future<void> _launch(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silent — a bad link shouldn't break reading the note.
    }
  }

  MarkdownStyleSheet _styleSheet() {
    final body = GoogleFonts.inter(
      fontSize: 14.5,
      height: 1.62,
      color: AppTheme.textPrimary.withValues(alpha: 0.92),
    );
    return MarkdownStyleSheet(
      p: body,
      pPadding: const EdgeInsets.only(bottom: 10),
      h1: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
      h2: GoogleFonts.outfit(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      h3: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      h3Padding: const EdgeInsets.only(top: 6, bottom: 6),
      listBullet: body,
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 18,
      strong: body.copyWith(
          fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      em: body.copyWith(fontStyle: FontStyle.italic),
      blockquote: body.copyWith(color: AppTheme.textPrimary),
      blockquoteDecoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
            left: BorderSide(color: AppTheme.primary, width: 3.5)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      code: GoogleFonts.robotoMono(
        fontSize: 13,
        backgroundColor: AppTheme.primaryLight,
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      tableHead: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      tableBody: GoogleFonts.inter(
          fontSize: 13, height: 1.45, color: AppTheme.textPrimary),
      tableHeadAlign: TextAlign.left,
      tableBorder: TableBorder.all(color: AppTheme.borderLight, width: 1),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tableColumnWidth: const IntrinsicColumnWidth(),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      a: body.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline),
    );
  }
}

/// One diagram, rendered from inline SVG markup. Tall diagrams stay readable by
/// scaling to the card width.
class _Diagram extends StatelessWidget {
  const _Diagram({required this.svg});
  final String svg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.space3),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: SvgPicture.string(
        svg,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of the remaining sections for non-members.
class _PaywallCard extends StatelessWidget {
  const _PaywallCard({required this.hiddenCount, required this.onUnlock});
  final int hiddenCount;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space5),
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.06),
            AppTheme.primaryLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                color: AppTheme.primary, size: 26),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            hiddenCount > 0
                ? '$hiddenCount more section${hiddenCount == 1 ? '' : 's'} in this note'
                : 'Continue reading',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unlock full theory notes — worked examples, shortcuts, '
            'common traps and quick revision — for every topic.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          AppButton(
            label: 'Unlock with Membership',
            icon: Icons.workspace_premium_rounded,
            onPressed: onUnlock,
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });
  final String? number;
  final String? title;
  final String body;
}

class _Segment {
  const _Segment(this.text, this.isSvg);
  final String text;
  final bool isSvg;
}
