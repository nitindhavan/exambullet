import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language selection + on-device translation (Google ML Kit).
///
/// English is the source language and the default. Picking another language
/// translates dynamic CONTENT (mock-test questions/options/explanations and
/// exam/test/topic names) at render time via [translate], with a per-session
/// in-memory cache. Language models (~30 MB each) are downloaded on demand when
/// a language is selected — see [downloadModel] / [isModelDownloaded].
///
/// ML Kit is native-only, so everything is guarded behind `!kIsWeb`: on web,
/// [translate] is a pass-through and the picker should stay hidden.
///
/// Mirrors the app's singleton convention (Analytics.instance, PresenceService).
class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const String _prefsKey = 'app_language_v1';
  static const String sourceLang = 'en';

  /// Supported target languages: label + BCP-47 code (ML Kit [TranslateLanguage]).
  /// English is the always-available source (no download / no translation).
  static const List<LanguageOption> supported = [
    LanguageOption('English', 'en'),
    LanguageOption('हिन्दी (Hindi)', 'hi'),
    LanguageOption('বাংলা (Bengali)', 'bn'),
    LanguageOption('தமிழ் (Tamil)', 'ta'),
    LanguageOption('తెలుగు (Telugu)', 'te'),
    LanguageOption('मराठी (Marathi)', 'mr'),
    LanguageOption('ગુજરાતી (Gujarati)', 'gu'),
    LanguageOption('ಕನ್ನಡ (Kannada)', 'kn'),
    LanguageOption('اردو (Urdu)', 'ur'),
  ];

  /// Current language code (BCP-47). 'en' = no translation. Rebuild UI that
  /// depends on it via [ValueListenableBuilder].
  final ValueNotifier<String> current = ValueNotifier<String>(sourceLang);

  final _modelManager = OnDeviceTranslatorModelManager();

  // Per-session caches (cleared on restart, per the chosen design).
  //   langCode -> (sourceText -> translatedText)
  final Map<String, Map<String, String>> _cache = {};
  //   langCode -> a reusable translator instance
  final Map<String, OnDeviceTranslator> _translators = {};

  bool get isEnglish => current.value == sourceLang;

  /// Load the persisted language at startup. Safe to call on web (no-op-ish).
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && supported.any((l) => l.code == saved)) {
        current.value = saved;
      }
    } catch (e) {
      debugPrint('LanguageService init failed: $e');
    }
  }

  /// Switch the active language and persist it. The caller is responsible for
  /// ensuring the model is downloaded first (see [downloadModel]).
  Future<void> setLanguage(String code) async {
    if (current.value == code) return;
    current.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {}
  }

  /// True if the on-device model for [code] is present. English needs none.
  Future<bool> isModelDownloaded(String code) async {
    if (kIsWeb || code == sourceLang) return true;
    try {
      return await _modelManager.isModelDownloaded(code);
    } catch (_) {
      return false;
    }
  }

  /// Download the on-device model for [code] (~30 MB). [wifiOnly] gates it to
  /// un-metered networks. Returns true on success. No-op for English / web.
  Future<bool> downloadModel(String code, {bool wifiOnly = false}) async {
    if (kIsWeb || code == sourceLang) return true;
    try {
      return await _modelManager.downloadModel(code, isWifiRequired: wifiOnly);
    } catch (e) {
      debugPrint('downloadModel($code) failed: $e');
      return false;
    }
  }

  /// Delete a downloaded model to reclaim space.
  Future<bool> deleteModel(String code) async {
    if (kIsWeb || code == sourceLang) return true;
    try {
      _translators.remove(code)?.close();
      _cache.remove(code);
      return await _modelManager.deleteModel(code);
    } catch (_) {
      return false;
    }
  }

  OnDeviceTranslator _translatorFor(String code) {
    return _translators[code] ??= OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: _translateLang(code),
    );
  }

  /// Translate [text] into [lang] (defaults to the current global language).
  /// Returns [text] unchanged when the language is English, on web, or if
  /// translation fails (never throws — showing the source is better than an
  /// error). Passing [lang] lets a per-attempt test override the global setting.
  Future<String> translate(String text, {String? lang}) async {
    final code = lang ?? current.value;
    if (kIsWeb || code == sourceLang) return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final langCache = _cache.putIfAbsent(code, () => {});
    final cached = langCache[text];
    if (cached != null) return cached;

    try {
      final out = await _translatorFor(code).translateText(text);
      langCache[text] = out;
      return out;
    } catch (e) {
      debugPrint('translate failed ($code): $e');
      return text; // graceful fallback to source
    }
  }

  /// Synchronous cache peek for [lang] (defaults to current) — lets a widget
  /// show a translation instantly on rebuild if it was already translated this
  /// session (avoids a flicker back to English). Null if not yet cached.
  String? cached(String text, {String? lang}) {
    final code = lang ?? current.value;
    if (code == sourceLang) return text;
    return _cache[code]?[text];
  }

  // Lines that are pure markdown/structure — never send these to the translator
  // (SVG blocks are stripped separately by the caller).
  static final RegExp _svgBlock =
      RegExp(r'<svg[\s\S]*?<\/svg>', caseSensitive: false);
  static final RegExp _mdMarker =
      RegExp(r'^(\s*(?:#{1,6}\s+|[-*+]\s+|\d+[.)]\s+|>\s?))');

  /// Translate a Markdown note (with inline `<svg>` blocks) into [lang] while
  /// keeping markdown syntax and SVG markup intact. SVG blocks and code fences
  /// pass through untouched; table cells and prose are translated per-piece.
  /// Returns the source on English/web/failure. Whole-note result is cached.
  Future<String> translateMarkdown(String md, {String? lang}) async {
    final code = lang ?? current.value;
    if (kIsWeb || code == sourceLang || md.trim().isEmpty) return md;

    final noteCache = _cache.putIfAbsent('md:$code', () => {});
    final hit = noteCache[md];
    if (hit != null) return hit;

    try {
      // Split out SVG blocks — those pass through verbatim.
      final out = StringBuffer();
      var last = 0;
      for (final m in _svgBlock.allMatches(md)) {
        out.write(await _translateProse(md.substring(last, m.start), code));
        out.write(m.group(0)); // SVG untouched
        last = m.end;
      }
      out.write(await _translateProse(md.substring(last), code));
      final result = out.toString();
      noteCache[md] = result;
      return result;
    } catch (e) {
      debugPrint('translateMarkdown failed ($code): $e');
      return md;
    }
  }

  /// Translates the prose in a markdown chunk line by line, preserving leading
  /// markers (headings, bullets, block-quotes) and passing table rows / code
  /// fences through structurally (translating only the cell / code-comment text
  /// is overkill; table CELLS are translated, fences are left alone).
  Future<String> _translateProse(String chunk, String code) async {
    if (chunk.trim().isEmpty) return chunk;
    final lines = chunk.split('\n');
    final out = <String>[];
    var inFence = false;

    for (final line in lines) {
      final trimmed = line.trim();

      // Code fences: toggle, never translate their contents.
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        out.add(line);
        continue;
      }
      if (inFence || trimmed.isEmpty) {
        out.add(line);
        continue;
      }

      // Table row: translate each cell, keep the pipes/alignment.
      if (trimmed.startsWith('|')) {
        out.add(await _translateTableRow(line, code));
        continue;
      }

      // Prose / heading / bullet: strip the leading marker, translate the rest,
      // re-attach the marker so '## X' stays a heading.
      final marker = _mdMarker.firstMatch(line)?.group(1) ?? '';
      final body = line.substring(marker.length);
      if (body.trim().isEmpty) {
        out.add(line);
        continue;
      }
      out.add('$marker${await translate(body, lang: code)}');
    }
    return out.join('\n');
  }

  Future<String> _translateTableRow(String line, String code) async {
    // A divider row like | --- | --- | has no text — leave it.
    if (RegExp(r'^[\s|:\-]+$').hasMatch(line)) return line;
    final parts = line.split('|');
    for (var i = 0; i < parts.length; i++) {
      final cell = parts[i];
      if (cell.trim().isEmpty) continue;
      // Preserve the cell's surrounding whitespace.
      final lead = cell.substring(0, cell.length - cell.trimLeft().length);
      final trail =
          cell.substring(cell.trimRight().length);
      parts[i] = '$lead${await translate(cell.trim(), lang: code)}$trail';
    }
    return parts.join('|');
  }

  /// True for a language code that needs no translation (English / web).
  bool isSource(String code) => kIsWeb || code == sourceLang;

  /// Subject/section names that are English-language study (grammar, vocab,
  /// comprehension) — translating their questions would destroy them, so the
  /// picker locks these to English. Matched case-insensitively on the name.
  static bool isEnglishSubject(String subjectOrSection) {
    final s = subjectOrSection.toLowerCase();
    if (s.isEmpty) return false;
    // "English", "English Language", "General English", "English Comprehension",
    // "Verbal Ability in English", "Hindi and English Language", etc.
    return s.contains('english');
  }

  static TranslateLanguage _translateLang(String code) {
    final match = TranslateLanguage.values.firstWhere(
      (l) => l.bcpCode == code,
      orElse: () => TranslateLanguage.english,
    );
    return match;
  }
}

class LanguageOption {
  const LanguageOption(this.label, this.code);
  final String label;
  final String code;
}
