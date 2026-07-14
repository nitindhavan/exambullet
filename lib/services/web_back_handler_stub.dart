import 'package:flutter/widgets.dart';

/// Native no-op stub. On mobile the OS back button already pops the Navigator,
/// so there is nothing to bridge. Mirrors the web API so call sites are uniform.
class WebBackHandler {
  WebBackHandler._();
  static final WebBackHandler instance = WebBackHandler._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorObserver? get observer => null;

  void install() {}
}
