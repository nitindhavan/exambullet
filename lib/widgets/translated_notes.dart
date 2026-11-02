import 'package:flutter/material.dart';
import 'package:percent/services/language_service.dart';
import 'package:percent/widgets/notes_markdown.dart';
import 'package:percent/widgets/percent_loader.dart';

/// Renders a theory note translated into the app's current language.
///
/// Unlike per-question translation (which is done inline per visible string), a
/// note is one large markdown+SVG blob that must be translated BEFORE render so
/// markdown syntax and SVG markup stay intact (see
/// [LanguageService.translateMarkdown]). So this widget translates the whole
/// note once — showing a loader while it works — then hands the finished string
/// to [NotesMarkdown]. Rebuilds when the language changes.
class TranslatedNotes extends StatelessWidget {
  const TranslatedNotes({
    Key? key,
    required this.content,
    this.lang,
    this.maxSections,
    this.onUnlock,
  }) : super(key: key);

  final String content;

  /// Fixed language for this note (per-topic selection). When null, follows the
  /// global [LanguageService.current].
  final String? lang;

  final int? maxSections;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    if (lang != null) return _forLang(context, lang!);
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.instance.current,
      builder: (context, current, _) => _forLang(context, current),
    );
  }

  Widget _forLang(BuildContext context, String code) {
    // English / web: render directly, no translation pass.
    if (LanguageService.instance.isSource(code)) return _render(content);
    return FutureBuilder<String>(
      future: LanguageService.instance.translateMarkdown(content, lang: code),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const PercentLoaderCentered();
        }
        return _render(snap.data ?? content);
      },
    );
  }

  Widget _render(String data) => NotesMarkdown(
        data: data,
        maxSections: maxSections,
        onUnlock: onUnlock,
      );
}
