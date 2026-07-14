/// Native stub — the "download app" UI is web-only, so this is never reached
/// (callers guard with kIsWeb). Present only so native builds compile.
bool get isAndroidBrowser => false;
