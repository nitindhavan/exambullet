/// Browser-Back → Flutter-Navigator bridge (web only; no-op on native).
///
/// Import this; the right implementation is selected at compile time.
export 'web_back_handler_stub.dart'
    if (dart.library.js_interop) 'web_back_handler_web.dart';
