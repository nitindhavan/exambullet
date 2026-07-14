import 'package:web/web.dart' as web;

/// True when the browser's user-agent looks like Android. Web-only.
bool get isAndroidBrowser {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    // Android but not "windows" (some desktop UAs mention "android" in tokens
    // rarely) — the simple contains check is sufficient in practice.
    return ua.contains('android');
  } catch (_) {
    return false;
  }
}
