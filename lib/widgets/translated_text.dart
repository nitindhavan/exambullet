import 'package:flutter/material.dart';
import 'package:percent/services/language_service.dart';

/// A [Text] that shows [source] translated into the app's current language.
///
/// Behaviour:
///  - English (or web): renders [source] directly, zero overhead.
///  - Other language, already cached this session: renders the translation
///    immediately (no flicker).
///  - Other language, not yet cached: renders [source] first, then swaps to the
///    translation when ML Kit resolves. On any failure it just keeps [source].
///
/// Rebuilds automatically when the language changes (listens to
/// [LanguageService.current]).
class TranslatedText extends StatelessWidget {
  const TranslatedText(
    this.source, {
    Key? key,
    this.lang,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : super(key: key);

  final String source;

  /// Fixed language for this text (e.g. a per-attempt test language). When null,
  /// follows the app-wide [LanguageService.current] and rebuilds on change.
  final String? lang;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    // Fixed-language mode: no global listener, translate to [lang] directly.
    if (lang != null) return _build(context, lang!);

    // Global mode: follow the current language and rebuild when it changes.
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.instance.current,
      builder: (context, current, _) => _build(context, current),
    );
  }

  Widget _build(BuildContext context, String code) {
    final svc = LanguageService.instance;
    // Fast paths: English/web, empty, or already-translated this session.
    final immediate = svc.cached(source, lang: code);
    if (svc.isSource(code) || immediate != null) {
      return _text(immediate ?? source);
    }
    // Not cached yet — show source now, translation when it arrives.
    return FutureBuilder<String>(
      future: svc.translate(source, lang: code),
      builder: (context, snap) => _text(snap.data ?? source),
    );
  }

  Widget _text(String value) => Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
}
