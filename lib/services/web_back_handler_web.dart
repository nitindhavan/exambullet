import 'dart:js_interop';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Bridges the browser Back button to the Flutter Navigator on web.
///
/// Problem: this app navigates imperatively (`Navigator.push`). On Flutter web
/// that does NOT create browser history entries, so the browser's Back button
/// skips every in-app screen and leaves the page entirely — inside Instagram's
/// in-app browser that reads as "the browser just closed".
///
/// Fix: keep one spare history entry in front of the app. Every time a route is
/// pushed we add a browser history state; when the user presses Back the browser
/// fires `popstate` instead of unloading the page — we intercept it, pop the
/// Flutter Navigator, and immediately re-add a spare state so the next Back also
/// stays in-app. Only when the Flutter Navigator can't pop (we're at the root)
/// do we let the browser actually go back (exit the app).
class WebBackHandler {
  WebBackHandler._();
  static final WebBackHandler instance = WebBackHandler._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _installed = false;

  late final _observer = _HistoryObserver(_onRoutePushed);
  NavigatorObserver get observer => _observer;

  void install() {
    if (_installed) return;
    _installed = true;
    _pushSpareState();
    web.window.addEventListener('popstate', _onPopState.toJS);
  }

  void _pushSpareState() {
    try {
      web.window.history.pushState(null, '', web.window.location.href);
    } catch (_) {}
  }

  void _onRoutePushed() {
    // A new in-app screen appeared → ensure a spare history entry sits in front
    // of it for the browser Back to consume instead of leaving the page.
    _pushSpareState();
  }

  void _onPopState(web.PopStateEvent event) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    if (nav.canPop()) {
      nav.pop();
      _pushSpareState(); // restore a spare so the next Back also stays in-app
    }
    // At the root (can't pop) we do nothing — the browser has already gone back,
    // correctly letting the user leave the app.
  }
}

/// Small NavigatorObserver that fires [onPushed] whenever a non-root route is
/// pushed, so we can add a matching browser history entry.
class _HistoryObserver extends NavigatorObserver {
  _HistoryObserver(this.onPushed);
  final void Function() onPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) onPushed(); // skip the very first root route
  }
}
